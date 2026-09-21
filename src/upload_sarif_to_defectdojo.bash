#!/usr/bin/env bash
# shellcheck shell=bash

## @file src/upload_sarif_to_defectdojo.bash
## @author CQPFC Team
## @brief a shell script to automate uploading SARIF results to DefectDojo
## @details
## This is a shell script that will iterate across a series of filenames
## passed in and upload the results to a DefectDojo instance.  This
## hope is to have one process generate SARIF results (e.g., Megalinter)
## so that this script can upload the results.
##
## There exist actions in the GitHub Actions Marketplace that will
## upload SARIF results to DefectDojo, such as:
## https://github.com/marketplace/actions/defectdojo-import-scan
##
## However, we want to be able to be able to upload results to
## an internal, non-Internet-accessible DefectDojo instance, potentially
## using an internal CI/CD system (e.g., a Jenkins instance).
##
## Configuration for the tool is expected to be provided by environment
## variables; this is to support clean integration with a CI/CD
## system that populates environment variables rather than using
## flags.  Additionally, the tool is able to use a configuration
## file (e.g., `.env`) that can provide values.
##
## The expected usage pattern is for a repository to include a
## configuration file with parameters like project name, whether
## or not to push results to Jira, etc. and environment variables to
## pass server details and authentication credentials.  It's possible
## to use all environment variables or all configuration files or
## some mix.
##
## The script supports passing multiple files to be uploaded, even
## if those files are in different locations or even associated with
## different projects. In situations like these, a configuration
## file for each location is supported.
##
## Several locations for configuration files are searched with the
## first one found being used:
##
## 1. current directory's uploadsarifdd.conf
## 2. current directory's .uploadsarifdd.conf
## 3. file's repo's uploadsarifdd.conf
## 4. file's repo's .uploadsarif.dd.conf
## 5. ~/uploadsarifdd.conf
## 6. ~/.uploadsarifdd.conf

set -euo pipefail

## @var UPLOAD_SARIF_USAGE_OVERVIEW
## @brief Stable overview text used by every generated artifact flavor.
readonly UPLOAD_SARIF_USAGE_OVERVIEW='a shell script to automate uploading SARIF results to DefectDojo'

## @var UPLOAD_SARIF_USAGE_TEXT
## @brief Stable option text used by every generated artifact flavor.
readonly UPLOAD_SARIF_USAGE_TEXT=
# Maintained source may be executed directly after `make deps`.  Generated
# consumer artifacts embed bashlog before this source, so this branch is skipped
# in the standalone public executable.
if ! declare -F bashlog_info >/dev/null 2>&1; then
  __upload_sarif_source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  __upload_sarif_bashlog="${__upload_sarif_source_dir}/../vendor/bashlog.dev.bash"

  if [ ! -r "$__upload_sarif_bashlog" ]; then
    printf '%s\n' \
      'Missing vendor/bashlog.dev.bash; run make deps or execute the built root artifact.' \
      >&2
    if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
      exit 1
    fi
    return 1
  fi

  # shellcheck disable=SC1090
  source "$__upload_sarif_bashlog"
  unset __upload_sarif_source_dir __upload_sarif_bashlog
fi
## @fn command_exists()
## @brief Determines whether a command is available in PATH.
## @details
## Performs a PATH lookup without executing the command.  The helper does not
## validate version or behavior.
##
## @param cmd Command name to locate.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The command is available in PATH.
## @retval 1 The command is not available in PATH.
##
## @par Examples
## @code
## if command_exists git; then
##   printf '%s\n' 'Git metadata enrichment is available.'
## fi
## @endcode

command_exists() {
  command -v "$1" >/dev/null 2>&1
}
## @fn is_git_repository()
## @brief Determines whether a path is contained in a Git work tree.
## @details
## Uses the supplied file or directory as the basis for repository discovery.
## File paths are resolved through their containing directory.  The path need not
## itself be tracked by Git.
##
## @param filename File or directory used as the discovery starting point.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The path is contained in a Git work tree.
## @retval 1 Git is unavailable or the path is not contained in a Git work tree.
##
## @par Examples
## @code
## if is_git_repository "megalinter-reports/sarif/report.sarif"; then
##   printf '%s\n' 'Repository metadata is available.'
## fi
## @endcode


is_git_repository() {
  # If git is not available, this host cannot perform repository introspection.
  # Returning non-zero allows callers to degrade gracefully under `set -euo pipefail`.
  command_exists git || return 1

  local target_dir
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1
}
## @fn git_branch()
## @brief Determines the branch identity associated with a repository path.
## @details
## Prefers the current symbolic branch name.  Detached HEAD states fall back to
## a non-HEAD abbreviated reference and then to the short commit SHA.
##
## @param filename File or directory used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The branch name or detached-HEAD short commit SHA is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing a branch name or short commit SHA.
##
## @retval 0 A branch identity or fallback SHA was determined.
## @retval 1 The repository identity could not be determined.
##
## @par Examples
## @code
## branch="$(git_branch "/path/to/repo/report.sarif")"
## @endcode


git_branch() {
  # If git is not available or the directory is not a repository, signal failure cleanly.
  command_exists git || return 1

  local target_dir branch sha
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  is_git_repository "$target_dir" || return 1

  # `git branch --show-current` returns an empty string for detached HEAD (common in CI).
  branch="$(git -C "$target_dir" branch --show-current 2>/dev/null || true)"
  if [ -n "$branch" ]; then
    printf '%s\n' "$branch"
    return 0
  fi

  # When detached, `--abbrev-ref HEAD` returns the literal string `HEAD`.
  branch="$(git -C "$target_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [ -n "$branch" ] && [ "$branch" != 'HEAD' ]; then
    printf '%s\n' "$branch"
    return 0
  fi

  # Final fallback: a short commit SHA is always meaningful and stable.
  sha="$(git -C "$target_dir" rev-parse --short HEAD 2>/dev/null || true)"
  [ -n "$sha" ] || return 1
  printf '%s\n' "$sha"
}
## @fn git_repository_root()
## @brief Determines the top-level directory of the containing Git work tree.
## @details
## Resolves the supplied file through its containing directory and returns the
## absolute work-tree root.  The file itself need not be tracked.
##
## @param filename File path used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The absolute repository root is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing the absolute repository root.
##
## @retval 0 The repository root was determined.
## @retval 1 The repository root could not be determined.
##
## @par Examples
## @code
## repo_root="$(git_repository_root "megalinter-reports/sarif/report.sarif")"
## @endcode


git_repository_root() {
  # If git is not available, the caller cannot infer repository-root configuration paths.
  command_exists git || return 1

  local filename target_dir repo_root
  filename="${1:-.}"
  target_dir="$(dirname -- "$filename")"

  is_git_repository "$target_dir" || return 1

  repo_root="$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$repo_root" ] || return 1
  printf '%s\n' "$repo_root"
}
## @fn get_scan_type()
## @brief Determines the DefectDojo scan type from a filename.
## @details
## Classifies supported scan-result filenames without reading their contents.
## SARIF filenames map to the DefectDojo scan type `SARIF`.
##
## @param filename Filename to classify.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The determined scan type is written as one line.
## @par STDERR
## An error log record is written when the filename cannot be classified.
##
## @returns One line containing the scan type when classification succeeds.
##
## @retval 0 A scan type was determined.
## @retval 1 The filename does not map to a supported scan type.
##
## @par Examples
## @code
## scan_type="$(get_scan_type "report.sarif")"
## @endcode



get_scan_type() {
  case "${1?No filename provided to get_scan_type}" in
    *.sarif)
      echo "SARIF"
      ;;
    *)
      bashlog_error 'Unable to determine scan type'
      return 1
      ;;
  esac
}
## @fn get_mime_type()
## @brief Determines the MIME type associated with a scan-result filename.
## @details
## Returns the known SARIF MIME type directly.  Other suffixes fall back to the
## `file` command and propagate its output and status.
##
## @param filename Filename or file path to classify.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The MIME type is written as one line when it can be determined.
## @par STDERR
## Diagnostics from the fallback `file` command may be written to STDERR.
##
## @returns One line containing the MIME type when classification succeeds.
##
## @retval 0 The MIME type was determined successfully.
## @note Non-zero exit statuses from the fallback `file` command may be propagated unchanged.
##
## @par Examples
## @code
## mime_type="$(get_mime_type "report.sarif")"
## @endcode


get_mime_type() {
  case "${1?No filename provded to get_mime_type}" in
    *.sarif)
      echo "application/SARIF"
      ;;
    *)
      file --brief --mime-type "$1"
      ;;
  esac
}
## @fn get_scan_date()
## @brief Determines the date associated with a scan report.
## @details
## Returns `DD_SCAN_DATE` when supplied.  Otherwise derives the date from the
## file modification timestamp and formats it as `YYYY-MM-DD`.
##
## @param filename Scan-result file whose modification time supplies the default date.
## @param DD_SCAN_DATE= Optional environment override for the returned scan date.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The selected scan date is written as one line.
## @par STDERR
## Diagnostics from `stat` or `date` may be written when derivation fails.
##
## @returns One line containing the selected scan date.
##
## @note Non-zero statuses from `stat` or `date` may affect command substitution.
##
## @par Examples
## @code
## scan_date="$(get_scan_date "report.sarif")"
## scan_date="$(DD_SCAN_DATE=2026-09-21 get_scan_date "report.sarif")"
## @endcode

get_scan_date() {
  local filename
  filename="${1?No filename provided to get_scan_date}"
  echo "${DD_SCAN_DATE:-$(date +'%Y-%m-%d' -d "$(stat -L -c '%y' "$filename")")}"
}
## @fn get_scm_url()
## @brief Returns a sanitized origin URL for the containing Git repository.
## @details
## Reads `remote.origin.url`, removes a trailing `.git`, and removes embedded
## user information from common HTTPS and SSH-style remote forms.
##
## @param filename File or directory used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The sanitized source-management URL is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing the sanitized source-management URL.
##
## @retval 0 A usable origin URL was found and sanitized.
## @retval 1 No usable origin URL could be determined.
##
## @par Examples
## @code
## scm_url="$(get_scm_url "/path/to/repo/report.sarif")"
## @endcode

get_scm_url() {
  # If git is not available or the directory is not a repository, return non-zero without exiting the script.
  command_exists git || return 1

  local target_dir url
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  is_git_repository "$target_dir" || return 1

  url="$(git -C "$target_dir" config --get remote.origin.url 2>/dev/null || true)"
  [ -n "$url" ] || return 1

  url="${url%.git}"
  if [[ "$url" =~ ^([[:alpha:]][[:alnum:]+.-]*://)[^/@]+@(.*)$ ]]; then
    url="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  elif [[ "$url" == *@*:* ]]; then
    url="${url#*@}"
  fi

  printf '%s\n' "$url"
}
## @fn get_commit_hash()
## @brief Returns the full HEAD commit hash for the containing repository.
## @details
## Resolves a file or directory into its containing Git work tree and returns the
## full `HEAD` object name.
##
## @param filename File or directory used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The full HEAD commit hash is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing the full HEAD commit hash.
##
## @retval 0 The commit hash was determined.
## @retval 1 The commit hash could not be determined.
##
## @par Examples
## @code
## commit_hash="$(get_commit_hash "/path/to/repo/report.sarif")"
## @endcode


get_commit_hash() {
  # If git is not available or the directory is not a repository, return non-zero without exiting the script.
  command_exists git || return 1

  local target_dir commit
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  is_git_repository "$target_dir" || return 1

  commit="$(git -C "$target_dir" rev-parse HEAD 2>/dev/null || true)"
  [ -n "$commit" ] || return 1
  printf '%s\n' "$commit"
}
## @fn die()
## @brief Reports a trapped error and terminates the uploader.
## @details
## Intended for the ERR trap installed by `main`.  Writes an error summary and
## emits stack-frame and source-line context before terminating with status 1.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Stack-frame descriptions and matching source lines are written for available frames.
## @par STDERR
## A one-line error summary containing status, source file, and line number is written.
##
## @returns Zero or more stack-frame and source-context lines are written to STDOUT before termination.
##
## @retval 1 The function always terminates the process with failure.
##
## @par Examples
## @code
## trap die ERR
## @endcode



die() {
  printf "ERROR %s in %s AT LINE %s\n" "$?" "${BASH_SOURCE[0]}" "${BASH_LINENO[0]}" 1>&2

  local i=0
  local FRAMES=${#BASH_LINENO[@]}

  # FRAMES-2 skips main, the last one in arrays
  for ((i = FRAMES - 2; i >= 0; i--)); do
    printf "  File \"%s\", line %s, in %s\n" "${BASH_SOURCE[i + 1]}" "${BASH_LINENO[i]}" "${FUNCNAME[i + 1]}"
    # Grab the source code of the line
    sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i + 1]}"
  done
  exit 1
}
## @fn display_usage()
## @brief Generates overview and option usage text from the current script.
## @details
## Uses maintained executable overview and option text so documented,
## comment-stripped, and minified artifacts preserve identical help output.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Generated overview and option usage sections are written when available.
## @par STDERR
## Nothing is written to STDERR by the help renderer itself.
##
## @returns Zero or more human-readable usage lines.
##
## @retval 0 The maintained help text was rendered.
##
## @par Examples
## @code
## display_usage
## @endcode


display_usage() {
  local overview
  overview="$UPLOAD_SARIF_USAGE_OVERVIEW"

  local usage
  usage="$UPLOAD_SARIF_USAGE_TEXT"

  if [ -n "$overview" ]; then
    printf "Overview\n%s\n" "$overview"
  fi

  if [ -n "$usage" ]; then
    printf "\nUsage:\n%s\n" "$usage"
  fi
}
## @fn print_curl_command_redacted()
## @brief Prints a redacted, shell-escaped curl command for diagnostics.
## @details
## Renders the named curl-command array while replacing the DefectDojo
## Authorization token with `REDACTED`.  The routine must never emit the original
## API token.
##
## @param command_name Name of the array variable containing the curl command.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A dry-run heading and the redacted shell-escaped curl command are written.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The redacted command was rendered.
##
## @par Examples
## @code
## curl_command=(curl -H "Authorization: Token secret" https://dojo.example/)
## print_curl_command_redacted curl_command
## @endcode


print_curl_command_redacted() {
  local -n command_ref="$1"

  local -a redacted_command=()
  local argument

  for argument in "${command_ref[@]}"; do
    if [[ "$argument" == Authorization:\ Token\ * ]]; then
      redacted_command+=("Authorization: Token REDACTED")
      continue
    fi

    redacted_command+=("$argument")
  done

  printf '%s
' "Dry run (redacted):" 1>&2
  printf '%q ' "${redacted_command[@]}" 1>&2
  printf '
' 1>&2

  return 0
}
## @fn source_configuration_preserving_caller()
## @brief Sources trusted configuration while preserving caller-provided values.
## @details
## Snapshots supported variables, sources the selected trusted executable Bash
## configuration, and restores caller-provided values so command-line and
## environment settings retain precedence.  The configuration file executes with
## the uploader's privileges and may have arbitrary side effects.
##
## @param configuration_file Trusted Bash configuration file to source.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## An informational bashlog record identifies the imported configuration file.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The configuration was sourced and caller-owned values were restored.
## @note Non-zero statuses raised while sourcing the trusted configuration may be propagated.
##
## @par Examples
## @code
## DD_PRODUCT=caller-product source_configuration_preserving_caller ./uploadsarifdd.conf
## @endcode


source_configuration_preserving_caller() {
  local configuration_file="$1"
  local -a variables=(DD_TOKEN DD_PRODUCT DD_SERVER_HOST DD_SERVER_PROTO DD_SERVER_PATH DD_ACTIVE DD_CLOSE_OLD_FINDINGS DD_CLOSE_OLD_FINDINGS_PRODUCT_SCOPE DD_ENGAGEMENT DD_MINIMUM_SEVERITY DD_PUSH_TO_JIRA DD_SCAN_DATE DD_SCAN_TYPE DD_VERIFIED DD_FILE_TYPE DD_BRANCH DD_COMMIT_HASH DD_SCM_URL METHOD DRYRUN)
  local -A was_set=()
  local -A values=()
  local variable

  for variable in "${variables[@]}"; do
    if declare -p "$variable" >/dev/null 2>&1; then
      was_set["$variable"]=1
      values["$variable"]="${!variable}"
    fi
  done

  bashlog_info 'Importing configuration from %s' "$configuration_file"

  set -o allexport
  # shellcheck disable=SC1090
  source "$configuration_file"
  set +o allexport

  for variable in "${variables[@]}"; do
    if [ -n "${was_set[$variable]:-}" ]; then
      printf -v "$variable" '%s' "${values[$variable]}"
      export "${variable?}"
    fi
  done
}
## @fn process_scan_file()
## @brief Processes one scan-result path inside the caller's per-file isolation boundary.
## @details
## Resolves the selected configuration source, validates required DefectDojo
## settings, derives optional Git metadata, constructs the multipart curl
## invocation, and either renders the redacted dry-run command or performs the
## upload.  The caller invokes this helper in a subshell so configuration sourced
## for one scan cannot leak into subsequent inputs.  The dynamically scoped
## `explicit_configuration_sources` array is owned by `main`.
##
## @param filename Scan-result path to validate and upload.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Curl response data may be written when a real upload is performed.
## @par STDERR
## Operational bashlog records, validation diagnostics, and dry-run output may be written.
##
## @returns Zero or more response lines produced by curl.
##
## @retval 0 The file was uploaded, dry-run output was produced, or an unmatched glob required no work.
## @retval 1 The path or required configuration was invalid.
## @note Non-zero statuses from external commands may be propagated and handled by the caller's ERR trap.
##
## @par Examples
## @code
## (process_scan_file "report.sarif")
## @endcode
process_scan_file() {
  local filename="$1"

# If the file does not exist, we need to distinguish between:
#   (1) a caller-supplied explicit path that is genuinely missing 
#     (hard error), and
#   (2) an unmatched shell glob (e.g., *.sarif) that Bash passed through
#     literally (no work to do).
if [ ! -e "$filename" ]; then
  if [[ "$filename" == *[\*\?\[]* ]]; then
    bashlog_info 'No files matched pattern: %s' "$filename"
    exit 0
  fi

  bashlog_error 'file not found: %s' "$filename"
  exit 1
fi

# A path that exists but is not a regular file is not a valid upload target.
# This includes directories, devices, FIFOs, and other special files.
if [ ! -f "$filename" ]; then
  bashlog_error 'not a regular file: %s' "$filename"
  exit 1
fi
local -a form_values=()
local -a configuration_sources=()

if [ "${#explicit_configuration_sources[@]}" -gt 0 ]; then
  configuration_sources=("${explicit_configuration_sources[@]}")
else
  configuration_sources=("./uploadsarifdd.conf" "./.uploadsarifdd.conf")

  if is_git_repository "$filename"; then
    repo_root="$(git_repository_root "$filename")"

    configuration_sources+=("${repo_root}/uploadsarifdd.conf")
    configuration_sources+=("${repo_root}/.uploadsarifdd.conf")
  fi

  configuration_sources+=("${HOME}/uploadsarifdd.conf")
  configuration_sources+=("${HOME}/.uploadsarifdd.conf")
fi

local configuration_file=""
local configuration_candidate
local repo_root
local scm_url
local form_value
for configuration_candidate in "${configuration_sources[@]}"; do
  if [ -f "$configuration_candidate" ] && [ -r "$configuration_candidate" ]; then
    configuration_file="$configuration_candidate"
    break
  fi
done

if [ "${#explicit_configuration_sources[@]}" -gt 0 ] \
  && [ -z "$configuration_file" ]; then
  bashlog_error 'No readable explicit configuration file was found'
  exit 1
fi

if [ -n "$configuration_file" ]; then
  source_configuration_preserving_caller "$configuration_file"
fi

if [ -z "${DD_TOKEN:-}" ]; then
  bashlog_error 'No value for DD_TOKEN provided'
  exit 1
fi

if [ -z "${DD_PRODUCT:-}" ]; then
  bashlog_error 'No value for DD_PRODUCT provided'
  exit 1
fi

if [ -z "${DD_SERVER_HOST:-}" ]; then
  bashlog_error 'No value for DD_SERVER_HOST provided'
  exit 1
fi

# attach form values for DefectDojo's API
form_values+=("active=${DD_ACTIVE:-true}")
form_values+=("close_old_findings=${DD_CLOSE_OLD_FINDINGS:-false}")
form_values+=("close_old_findings_product_scope=${DD_CLOSE_OLD_FINDINGS_PRODUCT_SCOPE:-false}")
form_values+=("engagement_name=${DD_ENGAGEMENT:-cicd}")
form_values+=("minimum_severity=${DD_MINIMUM_SEVERITY:-Info}")
form_values+=("product_name=${DD_PRODUCT?No DD_PRODUCT provided}")
form_values+=("push_to_jira=${DD_PUSH_TO_JIRA:-false}")
form_values+=("scan_date=${DD_SCAN_DATE:-$(get_scan_date "$filename")}")
form_values+=("scan_type=${DD_SCAN_TYPE:-$(get_scan_type "$filename")}")
form_values+=("verified=${DD_VERIFIED:-true}")

# attach the filename of the scan results with curl's `@` notation
form_values+=("file=@${filename};type=${DD_FILE_TYPE:-$(get_mime_type "$filename")}")

if is_git_repository "$filename" \
  || [ -n "${DD_BRANCH:-}" ]; then
  form_values+=("branch=${DD_BRANCH:-$(git_branch "$filename")}")
fi

if is_git_repository "$filename" \
  || [ -n "${DD_COMMIT_HASH:-}" ]; then
  form_values+=("commit_hash=${DD_COMMIT_HASH:-$(get_commit_hash "$filename")}")
fi

if [ -n "${DD_SCM_URL:-}" ]; then
  form_values+=("source_code_management_uri=${DD_SCM_URL}")
elif is_git_repository "$filename"; then
  scm_url="$(get_scm_url "$filename" || true)"
  if [ -n "$scm_url" ]; then
    form_values+=("source_code_management_uri=${scm_url}")
  fi
fi
local -a curl_command=(curl -X "${METHOD:-POST}" "${DD_SERVER_PROTO:-https}://${DD_SERVER_HOST}${DD_SERVER_PATH:-/api/v2/import-scan/}" -H "accept: application/json" -H "Authorization: Token ${DD_TOKEN}")

for form_value in "${form_values[@]}"; do
  curl_command+=("-F" "$form_value")
done

if [ "${DRYRUN:-0}" = "1" ]; then
  print_curl_command_redacted curl_command
  exit 0
fi

"${curl_command[@]}"

}

## @fn main()
## @brief Parses uploader options and processes requested scan-result files.
## @details
## Normalizes long options, applies documented configuration precedence, derives
## optional Git metadata, constructs the DefectDojo multipart import request, and
## either renders a redacted dry-run command or invokes curl.  Each scan path is
## processed in a subshell so per-file configuration does not leak to later files.
##
## @param args[] Command-line options followed by zero or more scan-result paths.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Help text or curl response data may be written depending on the operation.
## @par STDERR
## Operational logs, validation diagnostics, trap diagnostics, and dry-run output may be written.
##
## @returns Zero or more result lines produced by help output or curl.
##
## @retval 0 The requested operation completed successfully.
## @retval 1 An input or operational failure occurred.
## @note Non-zero statuses from external commands may trigger the ERR trap and terminate through `die`.
##
## @par Examples
## @code
## DD_TOKEN=token main --product example --server dojo.example report.sarif
## main --help
## @endcode

main() {

  trap die ERR

  ###
  ### set values from their defaults here
  ###

  declare -a configuration_sources
  declare -a form_values

  for arg in "$@"; do
    shift
    case "$arg" in
      '--branch') set -- "$@" "-b" ;; ##- see -b
      '--config') set -- "$@" "-c" ;; ##- see -c
      '--date') set -- "$@" "-d" ;; ##- see -d
      '--dryrun') set -- "$@" "-D" ;; ##- see -D
      '--engagement') set -- "$@" "-e" ;; ##- see -e
      '--help') set -- "$@" "-h" ;; ##- see -h
      '--mime-type') set -- "$@" "-m" ;; ##- see -m
      '--product') set -- "$@" "-p" ;; ##- see -p
      '--server') set -- "$@" "-s" ;; ##- see -s
      '--severity') set -- "$@" "-S" ;; ##- see -S
      '--scan-type') set -- "$@" "-t" ;; ##- see -t
      '--url') set -- "$@" "-u" ;; ##- see -u
      *) set -- "$@" "$arg" ;;
    esac
  done

  OPTIND=1
  while getopts "b:c:d:De:hm:p:s:S:t:u:" opt; do
    case "$opt" in
      'b') DD_BRANCH="$OPTARG" ;; ##- set the branch to report
      'c') configuration_sources+=("$OPTARG") ;; ##- specify a configuration file
      'd') DD_SCAN_DATE="$OPTARG" ;; ##- set the scan date
      'D') DRYRUN="1" ;; ##- show curl command but don't send it
      'e') DD_ENGAGEMENT="$OPTARG" ;; ##- set the engagement
      'h')
           display_usage
                           exit 0
                                  ;; ##- view the help documentation
      'm') DD_FILE_TYPE="$OPTARG" ;; ##- set the MIME type of the file
      'p') DD_PRODUCT="$OPTARG" ;; ##- set the product
      's') DD_SERVER_HOST="$OPTARG" ;; ##- set the DefectDojo server
      'S') DD_MINIMUM_SEVERITY="$OPTARG" ;; ##- set the minimum severity to include
      't') DD_SCAN_TYPE="$OPTARG" ;; ##- set the type of scan we're reporting
      'u') DD_SCM_URL="$OPTARG" ;; ##- set the URL to the SCM
      *)
        printf "Invalid option '%s'" "$opt" 1>&2
        display_usage 1>&2
        exit 1
        ;;
    esac
  done

  shift "$((OPTIND - 1))"

  declare -a explicit_configuration_sources
  explicit_configuration_sources=("${configuration_sources[@]}")

  for filename in "$@"; do
    (process_scan_file "$filename")
  done
}

# if we're not being sourced and there's a function named `main`, run it
if [[ "$0" == "${BASH_SOURCE[0]}" ]] && [ "$(type -t "main")" = "function" ]; then
  main "$@"
fi
--branch\t\t: see -b\n--config\t\t: see -c\n--date\t\t: see -d\n--dryrun\t\t: see -D\n--engagement\t\t: see -e\n--help\t\t: see -h\n--mime-type\t\t: see -m\n--product\t\t: see -p\n--scan-type\t\t: see -t\n--server\t\t: see -s\n--severity\t\t: see -S\n--url\t\t: see -u\n-b\t\t: set the branch to report\n-c\t\t: specify a configuration file\n-d\t\t: set the scan date\n-D\t\t: show curl command but don\'t send it\n-e\t\t: set the engagement\n-m\t\t: set the MIME type of the file\n-p\t\t: set the product\n-s\t\t: set the DefectDojo server\n-S\t\t: set the minimum severity to include\n-t\t\t: set the type of scan we\'re reporting\n-u\t\t: set the URL to the SCM'

# Maintained source may be executed directly after `make deps`.  Generated
# consumer artifacts embed bashlog before this source, so this branch is skipped
# in the standalone public executable.
if ! declare -F bashlog_info >/dev/null 2>&1; then
  __upload_sarif_source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  __upload_sarif_bashlog="${__upload_sarif_source_dir}/../vendor/bashlog.dev.bash"

  if [ ! -r "$__upload_sarif_bashlog" ]; then
    printf '%s\n' \
      'Missing vendor/bashlog.dev.bash; run make deps or execute the built root artifact.' \
      >&2
    if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
      exit 1
    fi
    return 1
  fi

  # shellcheck disable=SC1090
  source "$__upload_sarif_bashlog"
  unset __upload_sarif_source_dir __upload_sarif_bashlog
fi
## @fn command_exists()
## @brief Determines whether a command is available in PATH.
## @details
## Performs a PATH lookup without executing the command.  The helper does not
## validate version or behavior.
##
## @param cmd Command name to locate.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The command is available in PATH.
## @retval 1 The command is not available in PATH.
##
## @par Examples
## @code
## if command_exists git; then
##   printf '%s\n' 'Git metadata enrichment is available.'
## fi
## @endcode

command_exists() {
  command -v "$1" >/dev/null 2>&1
}
## @fn is_git_repository()
## @brief Determines whether a path is contained in a Git work tree.
## @details
## Uses the supplied file or directory as the basis for repository discovery.
## File paths are resolved through their containing directory.  The path need not
## itself be tracked by Git.
##
## @param filename File or directory used as the discovery starting point.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The path is contained in a Git work tree.
## @retval 1 Git is unavailable or the path is not contained in a Git work tree.
##
## @par Examples
## @code
## if is_git_repository "megalinter-reports/sarif/report.sarif"; then
##   printf '%s\n' 'Repository metadata is available.'
## fi
## @endcode


is_git_repository() {
  # If git is not available, this host cannot perform repository introspection.
  # Returning non-zero allows callers to degrade gracefully under `set -euo pipefail`.
  command_exists git || return 1

  local target_dir
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1
}
## @fn git_branch()
## @brief Determines the branch identity associated with a repository path.
## @details
## Prefers the current symbolic branch name.  Detached HEAD states fall back to
## a non-HEAD abbreviated reference and then to the short commit SHA.
##
## @param filename File or directory used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The branch name or detached-HEAD short commit SHA is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing a branch name or short commit SHA.
##
## @retval 0 A branch identity or fallback SHA was determined.
## @retval 1 The repository identity could not be determined.
##
## @par Examples
## @code
## branch="$(git_branch "/path/to/repo/report.sarif")"
## @endcode


git_branch() {
  # If git is not available or the directory is not a repository, signal failure cleanly.
  command_exists git || return 1

  local target_dir branch sha
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  is_git_repository "$target_dir" || return 1

  # `git branch --show-current` returns an empty string for detached HEAD (common in CI).
  branch="$(git -C "$target_dir" branch --show-current 2>/dev/null || true)"
  if [ -n "$branch" ]; then
    printf '%s\n' "$branch"
    return 0
  fi

  # When detached, `--abbrev-ref HEAD` returns the literal string `HEAD`.
  branch="$(git -C "$target_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [ -n "$branch" ] && [ "$branch" != 'HEAD' ]; then
    printf '%s\n' "$branch"
    return 0
  fi

  # Final fallback: a short commit SHA is always meaningful and stable.
  sha="$(git -C "$target_dir" rev-parse --short HEAD 2>/dev/null || true)"
  [ -n "$sha" ] || return 1
  printf '%s\n' "$sha"
}
## @fn git_repository_root()
## @brief Determines the top-level directory of the containing Git work tree.
## @details
## Resolves the supplied file through its containing directory and returns the
## absolute work-tree root.  The file itself need not be tracked.
##
## @param filename File path used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The absolute repository root is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing the absolute repository root.
##
## @retval 0 The repository root was determined.
## @retval 1 The repository root could not be determined.
##
## @par Examples
## @code
## repo_root="$(git_repository_root "megalinter-reports/sarif/report.sarif")"
## @endcode


git_repository_root() {
  # If git is not available, the caller cannot infer repository-root configuration paths.
  command_exists git || return 1

  local filename target_dir repo_root
  filename="${1:-.}"
  target_dir="$(dirname -- "$filename")"

  is_git_repository "$target_dir" || return 1

  repo_root="$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$repo_root" ] || return 1
  printf '%s\n' "$repo_root"
}
## @fn get_scan_type()
## @brief Determines the DefectDojo scan type from a filename.
## @details
## Classifies supported scan-result filenames without reading their contents.
## SARIF filenames map to the DefectDojo scan type `SARIF`.
##
## @param filename Filename to classify.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The determined scan type is written as one line.
## @par STDERR
## An error log record is written when the filename cannot be classified.
##
## @returns One line containing the scan type when classification succeeds.
##
## @retval 0 A scan type was determined.
## @retval 1 The filename does not map to a supported scan type.
##
## @par Examples
## @code
## scan_type="$(get_scan_type "report.sarif")"
## @endcode



get_scan_type() {
  case "${1?No filename provided to get_scan_type}" in
    *.sarif)
      echo "SARIF"
      ;;
    *)
      bashlog_error 'Unable to determine scan type'
      return 1
      ;;
  esac
}
## @fn get_mime_type()
## @brief Determines the MIME type associated with a scan-result filename.
## @details
## Returns the known SARIF MIME type directly.  Other suffixes fall back to the
## `file` command and propagate its output and status.
##
## @param filename Filename or file path to classify.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The MIME type is written as one line when it can be determined.
## @par STDERR
## Diagnostics from the fallback `file` command may be written to STDERR.
##
## @returns One line containing the MIME type when classification succeeds.
##
## @retval 0 The MIME type was determined successfully.
## @note Non-zero exit statuses from the fallback `file` command may be propagated unchanged.
##
## @par Examples
## @code
## mime_type="$(get_mime_type "report.sarif")"
## @endcode


get_mime_type() {
  case "${1?No filename provded to get_mime_type}" in
    *.sarif)
      echo "application/SARIF"
      ;;
    *)
      file --brief --mime-type "$1"
      ;;
  esac
}
## @fn get_scan_date()
## @brief Determines the date associated with a scan report.
## @details
## Returns `DD_SCAN_DATE` when supplied.  Otherwise derives the date from the
## file modification timestamp and formats it as `YYYY-MM-DD`.
##
## @param filename Scan-result file whose modification time supplies the default date.
## @param DD_SCAN_DATE= Optional environment override for the returned scan date.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The selected scan date is written as one line.
## @par STDERR
## Diagnostics from `stat` or `date` may be written when derivation fails.
##
## @returns One line containing the selected scan date.
##
## @note Non-zero statuses from `stat` or `date` may affect command substitution.
##
## @par Examples
## @code
## scan_date="$(get_scan_date "report.sarif")"
## scan_date="$(DD_SCAN_DATE=2026-09-21 get_scan_date "report.sarif")"
## @endcode

get_scan_date() {
  local filename
  filename="${1?No filename provided to get_scan_date}"
  echo "${DD_SCAN_DATE:-$(date +'%Y-%m-%d' -d "$(stat -L -c '%y' "$filename")")}"
}
## @fn get_scm_url()
## @brief Returns a sanitized origin URL for the containing Git repository.
## @details
## Reads `remote.origin.url`, removes a trailing `.git`, and removes embedded
## user information from common HTTPS and SSH-style remote forms.
##
## @param filename File or directory used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The sanitized source-management URL is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing the sanitized source-management URL.
##
## @retval 0 A usable origin URL was found and sanitized.
## @retval 1 No usable origin URL could be determined.
##
## @par Examples
## @code
## scm_url="$(get_scm_url "/path/to/repo/report.sarif")"
## @endcode

get_scm_url() {
  # If git is not available or the directory is not a repository, return non-zero without exiting the script.
  command_exists git || return 1

  local target_dir url
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  is_git_repository "$target_dir" || return 1

  url="$(git -C "$target_dir" config --get remote.origin.url 2>/dev/null || true)"
  [ -n "$url" ] || return 1

  url="${url%.git}"
  if [[ "$url" =~ ^([[:alpha:]][[:alnum:]+.-]*://)[^/@]+@(.*)$ ]]; then
    url="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  elif [[ "$url" == *@*:* ]]; then
    url="${url#*@}"
  fi

  printf '%s\n' "$url"
}
## @fn get_commit_hash()
## @brief Returns the full HEAD commit hash for the containing repository.
## @details
## Resolves a file or directory into its containing Git work tree and returns the
## full `HEAD` object name.
##
## @param filename File or directory used as the repository discovery basis.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The full HEAD commit hash is written as one line.
## @par STDERR
## Nothing is written to STDERR; Git diagnostics are suppressed.
##
## @returns One line containing the full HEAD commit hash.
##
## @retval 0 The commit hash was determined.
## @retval 1 The commit hash could not be determined.
##
## @par Examples
## @code
## commit_hash="$(get_commit_hash "/path/to/repo/report.sarif")"
## @endcode


get_commit_hash() {
  # If git is not available or the directory is not a repository, return non-zero without exiting the script.
  command_exists git || return 1

  local target_dir commit
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  is_git_repository "$target_dir" || return 1

  commit="$(git -C "$target_dir" rev-parse HEAD 2>/dev/null || true)"
  [ -n "$commit" ] || return 1
  printf '%s\n' "$commit"
}
## @fn die()
## @brief Reports a trapped error and terminates the uploader.
## @details
## Intended for the ERR trap installed by `main`.  Writes an error summary and
## emits stack-frame and source-line context before terminating with status 1.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Stack-frame descriptions and matching source lines are written for available frames.
## @par STDERR
## A one-line error summary containing status, source file, and line number is written.
##
## @returns Zero or more stack-frame and source-context lines are written to STDOUT before termination.
##
## @retval 1 The function always terminates the process with failure.
##
## @par Examples
## @code
## trap die ERR
## @endcode



die() {
  printf "ERROR %s in %s AT LINE %s\n" "$?" "${BASH_SOURCE[0]}" "${BASH_LINENO[0]}" 1>&2

  local i=0
  local FRAMES=${#BASH_LINENO[@]}

  # FRAMES-2 skips main, the last one in arrays
  for ((i = FRAMES - 2; i >= 0; i--)); do
    printf "  File \"%s\", line %s, in %s\n" "${BASH_SOURCE[i + 1]}" "${BASH_LINENO[i]}" "${FUNCNAME[i + 1]}"
    # Grab the source code of the line
    sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i + 1]}"
  done
  exit 1
}
## @fn display_usage()
## @brief Generates overview and option usage text from the current script.
## @details
## Uses maintained executable overview data so documented, comment-stripped, and
## minified artifacts preserve the same help text.  Option annotations are
## extracted from executable lines in the current script.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Generated overview and option usage sections are written when available.
## @par STDERR
## Diagnostics from `sed` or `sort` may be written if extraction fails.
##
## @returns Zero or more human-readable usage lines.
##
## @retval 0 Usage extraction completed without a propagated command failure.
## @note Non-zero statuses from `sed` or `sort` may be propagated when extraction fails.
##
## @par Examples
## @code
## display_usage
## @endcode


display_usage() {
  local overview
  overview="$UPLOAD_SARIF_USAGE_OVERVIEW"

  local usage
  usage="$(sed -Ene "s/^[[:space:]]*(['\"])([[:alnum:]]*)\1[[:space:]]*\).*##-[[:space:]]*(.*)/\-\2\t\t: \3/p" -e "s/^[[:space:]]*(['\"])([-[:alnum:]]*)*\1[[:space:]]*\)[[:space:]]*set[[:space:]]*--[[:space:]]*(['\"])[@$]*\3[[:space:]]*(['\"])(-[[:alnum:]])\4.*##-[[:space:]]*(.*)/\2\t\t: \6/p" < "$0" | sort -f)"

  if [ -n "$overview" ]; then
    printf "Overview\n%s\n" "$overview"
  fi

  if [ -n "$usage" ]; then
    printf "\nUsage:\n%s\n" "$usage"
  fi
}
## @fn print_curl_command_redacted()
## @brief Prints a redacted, shell-escaped curl command for diagnostics.
## @details
## Renders the named curl-command array while replacing the DefectDojo
## Authorization token with `REDACTED`.  The routine must never emit the original
## API token.
##
## @param command_name Name of the array variable containing the curl command.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## A dry-run heading and the redacted shell-escaped curl command are written.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The redacted command was rendered.
##
## @par Examples
## @code
## curl_command=(curl -H "Authorization: Token secret" https://dojo.example/)
## print_curl_command_redacted curl_command
## @endcode


print_curl_command_redacted() {
  local -n command_ref="$1"

  local -a redacted_command=()
  local argument

  for argument in "${command_ref[@]}"; do
    if [[ "$argument" == Authorization:\ Token\ * ]]; then
      redacted_command+=("Authorization: Token REDACTED")
      continue
    fi

    redacted_command+=("$argument")
  done

  printf '%s
' "Dry run (redacted):" 1>&2
  printf '%q ' "${redacted_command[@]}" 1>&2
  printf '
' 1>&2

  return 0
}
## @fn source_configuration_preserving_caller()
## @brief Sources trusted configuration while preserving caller-provided values.
## @details
## Snapshots supported variables, sources the selected trusted executable Bash
## configuration, and restores caller-provided values so command-line and
## environment settings retain precedence.  The configuration file executes with
## the uploader's privileges and may have arbitrary side effects.
##
## @param configuration_file Trusted Bash configuration file to source.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## An informational bashlog record identifies the imported configuration file.
##
## @returns Nothing is written to STDOUT.
##
## @retval 0 The configuration was sourced and caller-owned values were restored.
## @note Non-zero statuses raised while sourcing the trusted configuration may be propagated.
##
## @par Examples
## @code
## DD_PRODUCT=caller-product source_configuration_preserving_caller ./uploadsarifdd.conf
## @endcode


source_configuration_preserving_caller() {
  local configuration_file="$1"
  local -a variables=(DD_TOKEN DD_PRODUCT DD_SERVER_HOST DD_SERVER_PROTO DD_SERVER_PATH DD_ACTIVE DD_CLOSE_OLD_FINDINGS DD_CLOSE_OLD_FINDINGS_PRODUCT_SCOPE DD_ENGAGEMENT DD_MINIMUM_SEVERITY DD_PUSH_TO_JIRA DD_SCAN_DATE DD_SCAN_TYPE DD_VERIFIED DD_FILE_TYPE DD_BRANCH DD_COMMIT_HASH DD_SCM_URL METHOD DRYRUN)
  local -A was_set=()
  local -A values=()
  local variable

  for variable in "${variables[@]}"; do
    if declare -p "$variable" >/dev/null 2>&1; then
      was_set["$variable"]=1
      values["$variable"]="${!variable}"
    fi
  done

  bashlog_info 'Importing configuration from %s' "$configuration_file"

  set -o allexport
  # shellcheck disable=SC1090
  source "$configuration_file"
  set +o allexport

  for variable in "${variables[@]}"; do
    if [ -n "${was_set[$variable]:-}" ]; then
      printf -v "$variable" '%s' "${values[$variable]}"
      export "${variable?}"
    fi
  done
}
## @fn process_scan_file()
## @brief Processes one scan-result path inside the caller's per-file isolation boundary.
## @details
## Resolves the selected configuration source, validates required DefectDojo
## settings, derives optional Git metadata, constructs the multipart curl
## invocation, and either renders the redacted dry-run command or performs the
## upload.  The caller invokes this helper in a subshell so configuration sourced
## for one scan cannot leak into subsequent inputs.  The dynamically scoped
## `explicit_configuration_sources` array is owned by `main`.
##
## @param filename Scan-result path to validate and upload.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Curl response data may be written when a real upload is performed.
## @par STDERR
## Operational bashlog records, validation diagnostics, and dry-run output may be written.
##
## @returns Zero or more response lines produced by curl.
##
## @retval 0 The file was uploaded, dry-run output was produced, or an unmatched glob required no work.
## @retval 1 The path or required configuration was invalid.
## @note Non-zero statuses from external commands may be propagated and handled by the caller's ERR trap.
##
## @par Examples
## @code
## (process_scan_file "report.sarif")
## @endcode
process_scan_file() {
  local filename="$1"

# If the file does not exist, we need to distinguish between:
#   (1) a caller-supplied explicit path that is genuinely missing 
#     (hard error), and
#   (2) an unmatched shell glob (e.g., *.sarif) that Bash passed through
#     literally (no work to do).
if [ ! -e "$filename" ]; then
  if [[ "$filename" == *[\*\?\[]* ]]; then
    bashlog_info 'No files matched pattern: %s' "$filename"
    exit 0
  fi

  bashlog_error 'file not found: %s' "$filename"
  exit 1
fi

# A path that exists but is not a regular file is not a valid upload target.
# This includes directories, devices, FIFOs, and other special files.
if [ ! -f "$filename" ]; then
  bashlog_error 'not a regular file: %s' "$filename"
  exit 1
fi
local -a form_values=()
local -a configuration_sources=()

if [ "${#explicit_configuration_sources[@]}" -gt 0 ]; then
  configuration_sources=("${explicit_configuration_sources[@]}")
else
  configuration_sources=("./uploadsarifdd.conf" "./.uploadsarifdd.conf")

  if is_git_repository "$filename"; then
    repo_root="$(git_repository_root "$filename")"

    configuration_sources+=("${repo_root}/uploadsarifdd.conf")
    configuration_sources+=("${repo_root}/.uploadsarifdd.conf")
  fi

  configuration_sources+=("${HOME}/uploadsarifdd.conf")
  configuration_sources+=("${HOME}/.uploadsarifdd.conf")
fi

local configuration_file=""
local configuration_candidate
local repo_root
local scm_url
local form_value
for configuration_candidate in "${configuration_sources[@]}"; do
  if [ -f "$configuration_candidate" ] && [ -r "$configuration_candidate" ]; then
    configuration_file="$configuration_candidate"
    break
  fi
done

if [ "${#explicit_configuration_sources[@]}" -gt 0 ] \
  && [ -z "$configuration_file" ]; then
  bashlog_error 'No readable explicit configuration file was found'
  exit 1
fi

if [ -n "$configuration_file" ]; then
  source_configuration_preserving_caller "$configuration_file"
fi

if [ -z "${DD_TOKEN:-}" ]; then
  bashlog_error 'No value for DD_TOKEN provided'
  exit 1
fi

if [ -z "${DD_PRODUCT:-}" ]; then
  bashlog_error 'No value for DD_PRODUCT provided'
  exit 1
fi

if [ -z "${DD_SERVER_HOST:-}" ]; then
  bashlog_error 'No value for DD_SERVER_HOST provided'
  exit 1
fi

# attach form values for DefectDojo's API
form_values+=("active=${DD_ACTIVE:-true}")
form_values+=("close_old_findings=${DD_CLOSE_OLD_FINDINGS:-false}")
form_values+=("close_old_findings_product_scope=${DD_CLOSE_OLD_FINDINGS_PRODUCT_SCOPE:-false}")
form_values+=("engagement_name=${DD_ENGAGEMENT:-cicd}")
form_values+=("minimum_severity=${DD_MINIMUM_SEVERITY:-Info}")
form_values+=("product_name=${DD_PRODUCT?No DD_PRODUCT provided}")
form_values+=("push_to_jira=${DD_PUSH_TO_JIRA:-false}")
form_values+=("scan_date=${DD_SCAN_DATE:-$(get_scan_date "$filename")}")
form_values+=("scan_type=${DD_SCAN_TYPE:-$(get_scan_type "$filename")}")
form_values+=("verified=${DD_VERIFIED:-true}")

# attach the filename of the scan results with curl's `@` notation
form_values+=("file=@${filename};type=${DD_FILE_TYPE:-$(get_mime_type "$filename")}")

if is_git_repository "$filename" \
  || [ -n "${DD_BRANCH:-}" ]; then
  form_values+=("branch=${DD_BRANCH:-$(git_branch "$filename")}")
fi

if is_git_repository "$filename" \
  || [ -n "${DD_COMMIT_HASH:-}" ]; then
  form_values+=("commit_hash=${DD_COMMIT_HASH:-$(get_commit_hash "$filename")}")
fi

if [ -n "${DD_SCM_URL:-}" ]; then
  form_values+=("source_code_management_uri=${DD_SCM_URL}")
elif is_git_repository "$filename"; then
  scm_url="$(get_scm_url "$filename" || true)"
  if [ -n "$scm_url" ]; then
    form_values+=("source_code_management_uri=${scm_url}")
  fi
fi
local -a curl_command=(curl -X "${METHOD:-POST}" "${DD_SERVER_PROTO:-https}://${DD_SERVER_HOST}${DD_SERVER_PATH:-/api/v2/import-scan/}" -H "accept: application/json" -H "Authorization: Token ${DD_TOKEN}")

for form_value in "${form_values[@]}"; do
  curl_command+=("-F" "$form_value")
done

if [ "${DRYRUN:-0}" = "1" ]; then
  print_curl_command_redacted curl_command
  exit 0
fi

"${curl_command[@]}"

}

## @fn main()
## @brief Parses uploader options and processes requested scan-result files.
## @details
## Normalizes long options, applies documented configuration precedence, derives
## optional Git metadata, constructs the DefectDojo multipart import request, and
## either renders a redacted dry-run command or invokes curl.  Each scan path is
## processed in a subshell so per-file configuration does not leak to later files.
##
## @param args[] Command-line options followed by zero or more scan-result paths.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## Help text or curl response data may be written depending on the operation.
## @par STDERR
## Operational logs, validation diagnostics, trap diagnostics, and dry-run output may be written.
##
## @returns Zero or more result lines produced by help output or curl.
##
## @retval 0 The requested operation completed successfully.
## @retval 1 An input or operational failure occurred.
## @note Non-zero statuses from external commands may trigger the ERR trap and terminate through `die`.
##
## @par Examples
## @code
## DD_TOKEN=token main --product example --server dojo.example report.sarif
## main --help
## @endcode

main() {

  trap die ERR

  ###
  ### set values from their defaults here
  ###

  declare -a configuration_sources
  declare -a form_values

  for arg in "$@"; do
    shift
    case "$arg" in
      '--branch') set -- "$@" "-b" ;; ##- see -b
      '--config') set -- "$@" "-c" ;; ##- see -c
      '--date') set -- "$@" "-d" ;; ##- see -d
      '--dryrun') set -- "$@" "-D" ;; ##- see -D
      '--engagement') set -- "$@" "-e" ;; ##- see -e
      '--help') set -- "$@" "-h" ;; ##- see -h
      '--mime-type') set -- "$@" "-m" ;; ##- see -m
      '--product') set -- "$@" "-p" ;; ##- see -p
      '--server') set -- "$@" "-s" ;; ##- see -s
      '--severity') set -- "$@" "-S" ;; ##- see -S
      '--scan-type') set -- "$@" "-t" ;; ##- see -t
      '--url') set -- "$@" "-u" ;; ##- see -u
      *) set -- "$@" "$arg" ;;
    esac
  done

  OPTIND=1
  while getopts "b:c:d:De:hm:p:s:S:t:u:" opt; do
    case "$opt" in
      'b') DD_BRANCH="$OPTARG" ;; ##- set the branch to report
      'c') configuration_sources+=("$OPTARG") ;; ##- specify a configuration file
      'd') DD_SCAN_DATE="$OPTARG" ;; ##- set the scan date
      'D') DRYRUN="1" ;; ##- show curl command but don't send it
      'e') DD_ENGAGEMENT="$OPTARG" ;; ##- set the engagement
      'h')
           display_usage
                           exit 0
                                  ;; ##- view the help documentation
      'm') DD_FILE_TYPE="$OPTARG" ;; ##- set the MIME type of the file
      'p') DD_PRODUCT="$OPTARG" ;; ##- set the product
      's') DD_SERVER_HOST="$OPTARG" ;; ##- set the DefectDojo server
      'S') DD_MINIMUM_SEVERITY="$OPTARG" ;; ##- set the minimum severity to include
      't') DD_SCAN_TYPE="$OPTARG" ;; ##- set the type of scan we're reporting
      'u') DD_SCM_URL="$OPTARG" ;; ##- set the URL to the SCM
      *)
        printf "Invalid option '%s'" "$opt" 1>&2
        display_usage 1>&2
        exit 1
        ;;
    esac
  done

  shift "$((OPTIND - 1))"

  declare -a explicit_configuration_sources
  explicit_configuration_sources=("${configuration_sources[@]}")

  for filename in "$@"; do
    (process_scan_file "$filename")
  done
}

# if we're not being sourced and there's a function named `main`, run it
if [[ "$0" == "${BASH_SOURCE[0]}" ]] && [ "$(type -t "main")" = "function" ]; then
  main "$@"
fi
