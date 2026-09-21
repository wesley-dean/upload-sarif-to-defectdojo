#!/usr/bin/env bash

UPLOAD_SARIF_PROJECT_NAME=upload_sarif_to_defectdojo
UPLOAD_SARIF_VERSION=0.0.0-dev
UPLOAD_SARIF_BUILD_DATE=unknown
UPLOAD_SARIF_BUILD_COMMIT=unknown


BASHLOG_PROJECT_NAME=bashlog
BASHLOG_VERSION=0.0.18
BASHLOG_BUILD_DATE=2026-09-16T11:05:39-04:00
BASHLOG_BUILD_COMMIT=49351d22be4b


declare -g __bashlog_active_level=6

declare -g __bashlog_level_number=

declare -g __bashlog_level_name=

__bashlog_level_to_number() {
  if (( $# != 1 )); then
    return 64
  fi

  case $1 in
    emergency | 0) __bashlog_level_number=0 ;;
    alert | 1) __bashlog_level_number=1 ;;
    critical | 2) __bashlog_level_number=2 ;;
    error | 3) __bashlog_level_number=3 ;;
    warning | 4) __bashlog_level_number=4 ;;
    notice | 5) __bashlog_level_number=5 ;;
    info | 6) __bashlog_level_number=6 ;;
    debug | 7) __bashlog_level_number=7 ;;
    *) return 64 ;;
  esac

  return 0
}

__bashlog_level_to_name() {
  if (( $# != 1 )); then
    return 64
  fi

  case $1 in
    0) __bashlog_level_name=emergency ;;
    1) __bashlog_level_name=alert ;;
    2) __bashlog_level_name=critical ;;
    3) __bashlog_level_name=error ;;
    4) __bashlog_level_name=warning ;;
    5) __bashlog_level_name=notice ;;
    6) __bashlog_level_name=info ;;
    7) __bashlog_level_name=debug ;;
    *) return 64 ;;
  esac

  return 0
}

bashlog_level_get() {
  if (( $# != 0 )); then
    return 64
  fi

  __bashlog_level_to_name "${__bashlog_active_level}" || return 64
  printf '%s\n' "${__bashlog_level_name}"
}

bashlog_level_set() {
  local candidate

  if (( $# != 1 )); then
    return 64
  fi

  __bashlog_level_to_number "$1" || return 64
  candidate=${__bashlog_level_number}
  __bashlog_active_level=${candidate}
  return 0
}

declare -ga __bashlog_context_names=()

declare -ga __bashlog_context_states=()

declare -g __bashlog_context_count=0

declare -g __bashlog_context_index=-1

declare -ga __bashlog_rule_contexts=()

declare -ga __bashlog_rule_matchers=()

declare -ga __bashlog_rule_patterns=()

declare -ga __bashlog_rule_replacements=()

declare -g __bashlog_rule_count=0

declare -g __bashlog_match_start=-1

declare -g __bashlog_match_length=0

declare -g __bashlog_transform_result=

declare -g __bashlog_redacted_result=

__bashlog_context_name_valid() {
  local LC_ALL=C

  if (( $# != 1 )); then
    return 1
  fi

  [[ $1 =~ ^[A-Za-z_][A-Za-z0-9_.:-]*$ ]]
}

__bashlog_context_find() {
  local context=${1-}
  local index

  __bashlog_context_index=-1
  for ((index = 0; index < __bashlog_context_count; index++)); do
    if [ "${__bashlog_context_names[index]}" = "${context}" ]; then
      __bashlog_context_index=${index}
      return 0
    fi
  done

  return 1
}

__bashlog_context_resolve_active() {
  if (( $# != 1 )) || ! __bashlog_context_name_valid "$1"; then
    return 64
  fi

  if ! __bashlog_context_find "$1"; then
    return 69
  fi

  if [ "${__bashlog_context_states[__bashlog_context_index]}" != active ]; then
    return 69
  fi

  return 0
}

__bashlog_glob_whole_match() {
  local restore_nocasematch=0
  local status

  if shopt -q nocasematch; then
    restore_nocasematch=1
    shopt -u nocasematch
  fi

  [[ $1 == $2 ]]
  status=$?

  if (( restore_nocasematch )); then
    shopt -s nocasematch
  fi

  return "${status}"
}

__bashlog_ere_match() {
  local restore_nocasematch=0
  local status

  if shopt -q nocasematch; then
    restore_nocasematch=1
    shopt -u nocasematch
  fi

  [[ $1 =~ $2 ]]
  status=$?

  if (( restore_nocasematch )); then
    shopt -s nocasematch
  fi

  return "${status}"
}

__bashlog_fixed_find_next() {
  local input=$1
  local pattern=$2
  local cursor=$3
  local input_length=${#input}
  local pattern_length=${#pattern}
  local start
  local slice

  __bashlog_match_start=-1
  __bashlog_match_length=0

  if (( pattern_length == 0 )); then
    return 2
  fi

  for ((start = cursor; start + pattern_length <= input_length; start++)); do
    slice=${input:start:pattern_length}
    if [ "${slice}" = "${pattern}" ]; then
      __bashlog_match_start=${start}
      __bashlog_match_length=${pattern_length}
      return 0
    fi
  done

  return 1
}

__bashlog_glob_find_next() {
  local input=$1
  local pattern=$2
  local cursor=$3
  local input_length=${#input}
  local start
  local length
  local slice

  __bashlog_match_start=-1
  __bashlog_match_length=0

  for ((start = cursor; start < input_length; start++)); do
    for ((length = input_length - start; length > 0; length--)); do
      slice=${input:start:length}
      if __bashlog_glob_whole_match "${slice}" "${pattern}"; then
        __bashlog_match_start=${start}
        __bashlog_match_length=${length}
        return 0
      fi
    done
  done

  return 1
}

__bashlog_ere_find_next() {
  local input=$1
  local pattern=$2
  local cursor=$3
  local input_length=${#input}
  local start
  local forced_pattern
  local status
  local matched

  __bashlog_match_start=-1
  __bashlog_match_length=0

  for ((start = cursor; start < input_length; start++)); do
    forced_pattern="^.{${start}}(${pattern})"
    __bashlog_ere_match "${input}" "${forced_pattern}"
    status=$?

    if (( status == 2 )); then
      return 2
    fi

    if (( status == 0 )); then
      matched=${BASH_REMATCH[1]-}
      if (( ${#matched} == 0 )); then
        return 2
      fi
      __bashlog_match_start=${start}
      __bashlog_match_length=${#matched}
      return 0
    fi
  done

  return 1
}

__bashlog_rule_matches() {
  local matcher=$1
  local pattern=$2
  local candidate=$3

  case ${matcher} in
    fixed)
      __bashlog_fixed_find_next "${candidate}" "${pattern}" 0
      return $?
      ;;
    glob)
      __bashlog_glob_find_next "${candidate}" "${pattern}" 0
      return $?
      ;;
    ere)
      __bashlog_ere_match "${candidate}" "${pattern}"
      return $?
      ;;
    *)
      return 2
      ;;
  esac
}

__bashlog_glob_has_extglob_operator() {
  local pattern=$1
  local operator

  for operator in '?(' '*(' '+(' '@(' '!('; do
    if __bashlog_fixed_find_next "${pattern}" "${operator}" 0; then
      return 0
    fi
  done

  return 1
}

__bashlog_rule_validate() {
  local matcher=$1
  local pattern=$2
  local replacement=$3
  local status

  if [ -z "${pattern}" ]; then
    return 65
  fi

  case ${matcher} in
    fixed)
      ;;
    glob)
      if __bashlog_glob_has_extglob_operator "${pattern}"; then
        return 65
      fi
      if __bashlog_glob_whole_match '' "${pattern}"; then
        return 65
      fi
      ;;
    ere)
      __bashlog_ere_match '' "${pattern}"
      status=$?
      if (( status == 0 || status == 2 )); then
        return 65
      fi
      ;;
    *)
      return 64
      ;;
  esac

  __bashlog_rule_matches "${matcher}" "${pattern}" "${replacement}"
  status=$?
  if (( status == 0 || status == 2 )); then
    return 65
  fi

  return 0
}

__bashlog_rule_apply() {
  local matcher=$1
  local pattern=$2
  local replacement=$3
  local input=$4
  local input_length=${#input}
  local cursor=0
  local prefix_length
  local status
  local result=

  while (( cursor < input_length )); do
    case ${matcher} in
      fixed) __bashlog_fixed_find_next "${input}" "${pattern}" "${cursor}" ;;
      glob) __bashlog_glob_find_next "${input}" "${pattern}" "${cursor}" ;;
      ere) __bashlog_ere_find_next "${input}" "${pattern}" "${cursor}" ;;
      *) return 70 ;;
    esac
    status=$?

    if (( status == 1 )); then
      break
    fi
    if (( status != 0 || __bashlog_match_length <= 0 )); then
      return 70
    fi

    prefix_length=$((__bashlog_match_start - cursor))
    result="${result}${input:cursor:prefix_length}${replacement}"
    cursor=$((__bashlog_match_start + __bashlog_match_length))
  done

  result="${result}${input:cursor}"
  __bashlog_transform_result=${result}
  return 0
}

__bashlog_context_transform() {
  local context_index=$1
  local candidate=$2
  local index

  for ((index = 0; index < __bashlog_rule_count; index++)); do
    if (( __bashlog_rule_contexts[index] != context_index )); then
      continue
    fi

    if ! __bashlog_rule_apply \
      "${__bashlog_rule_matchers[index]}" \
      "${__bashlog_rule_patterns[index]}" \
      "${__bashlog_rule_replacements[index]}" \
      "${candidate}"; then
      return 70
    fi
    candidate=${__bashlog_transform_result}
  done

  __bashlog_transform_result=${candidate}
  return 0
}

__bashlog_context_verify() {
  local context_index=$1
  local candidate=$2
  local index
  local status

  for ((index = 0; index < __bashlog_rule_count; index++)); do
    if (( __bashlog_rule_contexts[index] != context_index )); then
      continue
    fi

    __bashlog_rule_matches \
      "${__bashlog_rule_matchers[index]}" \
      "${__bashlog_rule_patterns[index]}" \
      "${candidate}"
    status=$?

    if (( status == 0 || status == 2 )); then
      return 70
    fi
  done

  return 0
}

__bashlog_redact_context() {
  local context_index=$1
  local input=$2
  local candidate

  __bashlog_redacted_result=

  if ! __bashlog_context_transform "${context_index}" "${input}"; then
    return 70
  fi
  candidate=${__bashlog_transform_result}

  if ! __bashlog_context_verify "${context_index}" "${candidate}"; then
    return 70
  fi

  __bashlog_redacted_result=${candidate}
  return 0
}

__bashlog_emit_suppression_diagnostic() {
  local context_index=$1
  local diagnostic='bashlog: message suppressed'

  if __bashlog_context_verify "${context_index}" "${diagnostic}"; then
    printf '%s\n' "${diagnostic}" >&2 || :
  fi

  return 0
}

bashlog_redaction_add() {
  local context
  local matcher
  local pattern
  local replacement
  local context_index=-1
  local index
  local validation_status

  if (( $# != 4 )); then
    return 64
  fi

  context=$1
  matcher=$2
  pattern=$3
  replacement=$4

  if ! __bashlog_context_name_valid "${context}"; then
    return 64
  fi

  case ${matcher} in
    fixed | glob | ere) ;;
    *) return 64 ;;
  esac

  if __bashlog_context_find "${context}"; then
    context_index=${__bashlog_context_index}
    if [ "${__bashlog_context_states[context_index]}" != active ]; then
      return 69
    fi
  fi

  if __bashlog_rule_validate "${matcher}" "${pattern}" "${replacement}"; then
    validation_status=0
  else
    validation_status=$?
  fi
  if (( validation_status != 0 )); then
    return "${validation_status}"
  fi

  if (( context_index >= 0 )); then
    for ((index = 0; index < __bashlog_rule_count; index++)); do
      if (( __bashlog_rule_contexts[index] != context_index )); then
        continue
      fi
      if [ "${__bashlog_rule_matchers[index]}" = "${matcher}" ] && \
        [ "${__bashlog_rule_patterns[index]}" = "${pattern}" ]; then
        return 65
      fi
    done
  else
    context_index=${__bashlog_context_count}
    __bashlog_context_names[context_index]=${context}
    __bashlog_context_states[context_index]=active
    __bashlog_context_count=$((__bashlog_context_count + 1))
  fi

  index=${__bashlog_rule_count}
  __bashlog_rule_contexts[index]=${context_index}
  __bashlog_rule_matchers[index]=${matcher}
  __bashlog_rule_patterns[index]=${pattern}
  __bashlog_rule_replacements[index]=${replacement}
  __bashlog_rule_count=$((__bashlog_rule_count + 1))

  return 0
}

bashlog_redaction_context_destroy() {
  local context_index
  local index
  local status

  if (( $# != 1 )); then
    return 64
  fi

  if __bashlog_context_resolve_active "$1"; then
    status=0
  else
    status=$?
  fi
  if (( status != 0 )); then
    return "${status}"
  fi

  context_index=${__bashlog_context_index}
  __bashlog_context_states[context_index]=destroyed

  for ((index = 0; index < __bashlog_rule_count; index++)); do
    if (( __bashlog_rule_contexts[index] != context_index )); then
      continue
    fi

    __bashlog_rule_contexts[index]=-1
    __bashlog_rule_matchers[index]=
    __bashlog_rule_patterns[index]=
    __bashlog_rule_replacements[index]=
  done

  return 0
}

bashlog_redact() {
  local context_index
  local status

  if (( $# != 2 )); then
    return 64
  fi

  if __bashlog_context_resolve_active "$1"; then
    status=0
  else
    status=$?
  fi
  if (( status != 0 )); then
    return "${status}"
  fi
  context_index=${__bashlog_context_index}

  if ! __bashlog_redact_context "${context_index}" "$2"; then
    __bashlog_emit_suppression_diagnostic "${context_index}"
    return 70
  fi

  if ! printf '%s' "${__bashlog_redacted_result}"; then
    return 70
  fi

  return 0
}

declare -g __bashlog_format_mode=auto

declare -g __bashlog_timestamp_mode=off

declare -g __bashlog_color_mode=auto

declare -ga __bashlog_level_style_colors=(red red red red yellow cyan green default)

declare -ga __bashlog_level_style_intensities=(bold bold bold normal normal normal normal dim)

declare -g __bashlog_resolved_format=

declare -g __bashlog_timestamp_value=

declare -g __bashlog_render_result=

declare -g __bashlog_logfmt_quoted_value=

declare -g __bashlog_human_color_code_value=

bashlog_format_get() {
  if (( $# != 0 )); then
    return 64
  fi

  printf '%s\n' "${__bashlog_format_mode}"
}

bashlog_format_set() {
  if (( $# != 1 )); then
    return 64
  fi

  case $1 in
    auto | human | logfmt) __bashlog_format_mode=$1 ;;
    *) return 64 ;;
  esac

  return 0
}

bashlog_timestamp_get() {
  if (( $# != 0 )); then
    return 64
  fi

  printf '%s\n' "${__bashlog_timestamp_mode}"
}

bashlog_timestamp_set() {
  if (( $# != 1 )); then
    return 64
  fi

  case $1 in
    off | utc | local) __bashlog_timestamp_mode=$1 ;;
    *) return 64 ;;
  esac

  return 0
}

bashlog_color_get() {
  if (( $# != 0 )); then
    return 64
  fi

  printf '%s\n' "${__bashlog_color_mode}"
}

bashlog_color_set() {
  if (( $# != 1 )); then
    return 64
  fi

  case $1 in
    never | auto | always) __bashlog_color_mode=$1 ;;
    *) return 64 ;;
  esac

  return 0
}

bashlog_level_style_get() {
  local level_number

  if (( $# != 1 )); then
    return 64
  fi

  __bashlog_level_to_number "$1" || return 64
  level_number=${__bashlog_level_number}
  printf '%s %s\n' \
    "${__bashlog_level_style_colors[level_number]}" \
    "${__bashlog_level_style_intensities[level_number]}"
}

bashlog_level_style_set() {
  local level_number
  local color
  local intensity

  if (( $# != 3 )); then
    return 64
  fi

  __bashlog_level_to_number "$1" || return 64
  level_number=${__bashlog_level_number}
  color=$2
  intensity=$3

  case ${color} in
    default | black | red | green | yellow | blue | magenta | cyan | white) ;;
    *) return 64 ;;
  esac

  case ${intensity} in
    normal | bold | dim) ;;
    *) return 64 ;;
  esac

  __bashlog_level_style_colors[level_number]=${color}
  __bashlog_level_style_intensities[level_number]=${intensity}
  return 0
}

bashlog_level_style_reset() {
  local level_number

  if (( $# > 1 )); then
    return 64
  fi

  if (( $# == 0 )); then
    __bashlog_level_style_colors=(red red red red yellow cyan green default)
    __bashlog_level_style_intensities=(bold bold bold normal normal normal normal dim)
    return 0
  fi

  __bashlog_level_to_number "$1" || return 64
  level_number=${__bashlog_level_number}

  case ${level_number} in
    0 | 1 | 2)
      __bashlog_level_style_colors[level_number]=red
      __bashlog_level_style_intensities[level_number]=bold
      ;;
    3)
      __bashlog_level_style_colors[level_number]=red
      __bashlog_level_style_intensities[level_number]=normal
      ;;
    4)
      __bashlog_level_style_colors[level_number]=yellow
      __bashlog_level_style_intensities[level_number]=normal
      ;;
    5)
      __bashlog_level_style_colors[level_number]=cyan
      __bashlog_level_style_intensities[level_number]=normal
      ;;
    6)
      __bashlog_level_style_colors[level_number]=green
      __bashlog_level_style_intensities[level_number]=normal
      ;;
    7)
      __bashlog_level_style_colors[level_number]=default
      __bashlog_level_style_intensities[level_number]=dim
      ;;
    *) return 64 ;;
  esac

  return 0
}

__bashlog_tag_valid() {
  local LC_ALL=C

  if (( $# != 1 )); then
    return 1
  fi

  [[ $1 =~ ^[A-Za-z0-9_.:-]+$ ]]
}

__bashlog_format_resolve() {
  case ${__bashlog_format_mode} in
    human | logfmt)
      __bashlog_resolved_format=${__bashlog_format_mode}
      ;;
    auto)
      if [[ -t 2 ]]; then
        __bashlog_resolved_format=human
      else
        __bashlog_resolved_format=logfmt
      fi
      ;;
    *)
      __bashlog_resolved_format=
      return 70
      ;;
  esac

  return 0
}

__bashlog_timestamp_utc() {
  local -x TZ=UTC0

  if ! printf -v __bashlog_timestamp_value '%(%Y-%m-%dT%H:%M:%SZ)T'; then
    __bashlog_timestamp_value=
    return 70
  fi

  return 0
}

__bashlog_timestamp_acquire() {
  __bashlog_timestamp_value=

  case ${__bashlog_timestamp_mode} in
    off)
      return 0
      ;;
    utc)
      __bashlog_timestamp_utc
      return $?
      ;;
    local)
      if ! printf -v __bashlog_timestamp_value '%(%Y-%m-%dT%H:%M:%S%z)T'; then
        __bashlog_timestamp_value=
        return 70
      fi
      ;;
    *)
      return 70
      ;;
  esac

  return 0
}

__bashlog_human_color_code() {
  local level_number
  local color
  local intensity
  local color_code=
  local intensity_code=

  if ! __bashlog_level_to_number "$1"; then
    __bashlog_human_color_code_value=
    return 70
  fi
  level_number=${__bashlog_level_number}
  color=${__bashlog_level_style_colors[level_number]}
  intensity=${__bashlog_level_style_intensities[level_number]}

  case ${color} in
    default) color_code= ;;
    black) color_code=30 ;;
    red) color_code=31 ;;
    green) color_code=32 ;;
    yellow) color_code=33 ;;
    blue) color_code=34 ;;
    magenta) color_code=35 ;;
    cyan) color_code=36 ;;
    white) color_code=37 ;;
    *)
      __bashlog_human_color_code_value=
      return 70
      ;;
  esac

  case ${intensity} in
    normal) intensity_code= ;;
    bold) intensity_code=1 ;;
    dim) intensity_code=2 ;;
    *)
      __bashlog_human_color_code_value=
      return 70
      ;;
  esac

  if [[ -n ${intensity_code} && -n ${color_code} ]]; then
    __bashlog_human_color_code_value="${intensity_code};${color_code}"
  else
    __bashlog_human_color_code_value="${intensity_code}${color_code}"
  fi

  return 0
}

__bashlog_human_color_enabled() {
  case ${__bashlog_color_mode} in
    never) return 1 ;;
    always) return 0 ;;
    auto)
      if [[ -t 2 ]]; then
        return 0
      fi
      return 1
      ;;
    *) return 70 ;;
  esac
}

__bashlog_logfmt_quote() {
  local value=${1-}
  local length=${#value}
  local result='"'
  local index
  local character
  local code
  local hex
  local control
  local encoded=0

  for ((index = 0; index < length; index++)); do
    character=${value:index:1}
    case ${character} in
      $'\\') result+="\\\\" ;;
      '"') result+="\\\"" ;;
      $'\t') result+="\\t" ;;
      $'\r') result+="\\r" ;;
      $'\n') result+="\\n" ;;
      *)
        encoded=0
        for ((code = 1; code < 32; code++)); do
          if (( code == 9 || code == 10 || code == 13 )); then
            continue
          fi
          printf -v hex '%02X' "${code}"
          printf -v control '%b' "\\x${hex}"
          if [[ ${character} == "${control}" ]]; then
            result+="\\u00${hex}"
            encoded=1
            break
          fi
        done
        if (( ! encoded )); then
          printf -v control '%b' '\x7F'
          if [[ ${character} == "${control}" ]]; then
            result+="\\u007F"
          else
            result+=${character}
          fi
        fi
        ;;
    esac
  done

  result+='"'
  __bashlog_logfmt_quoted_value=${result}
  return 0
}

__bashlog_render_human() {
  local level=$1
  local timestamp=$2
  local message=$3
  shift 3
  local candidate=
  local level_text=${level}
  local tag
  local color_status

  __bashlog_human_color_enabled
  color_status=$?
  if (( color_status == 70 )); then
    return 70
  fi
  if (( color_status == 0 )); then
    if ! __bashlog_human_color_code "${level}"; then
      return 70
    fi
    if [[ -n ${__bashlog_human_color_code_value} ]]; then
      level_text=$'\033['"${__bashlog_human_color_code_value}"$'m'"${level}"$'\033[0m'
    fi
  fi

  if [[ -n ${timestamp} ]]; then
    candidate="[${timestamp}] "
  fi
  candidate+="${level_text}"

  for tag in "$@"; do
    candidate+=" [${tag}]"
  done

  candidate+=": ${message}"
  __bashlog_render_result=${candidate}
  return 0
}

__bashlog_render_logfmt() {
  local level=$1
  local timestamp=$2
  local message=$3
  shift 3
  local candidate=
  local tag

  if [[ -n ${timestamp} ]]; then
    candidate="ts=${timestamp} "
  fi
  candidate+="level=${level}"

  for tag in "$@"; do
    if __bashlog_tag_valid "${tag}"; then
      candidate+=" tag=${tag}"
    else
      __bashlog_logfmt_quote "${tag}"
      candidate+=" tag=${__bashlog_logfmt_quoted_value}"
    fi
  done

  __bashlog_logfmt_quote "${message}"
  candidate+=" msg=${__bashlog_logfmt_quoted_value}"

  __bashlog_render_result=${candidate}
  return 0
}

__bashlog_render_record() {
  if ! __bashlog_format_resolve; then
    return 70
  fi

  case ${__bashlog_resolved_format} in
    human) __bashlog_render_human "$@" ;;
    logfmt) __bashlog_render_logfmt "$@" ;;
    *) return 70 ;;
  esac
}

bashlog_log() {
  local level
  local level_number
  local context_index=-1
  local context_seen=0
  local format
  local message
  local timestamp
  local candidate
  local status
  local tag
  local index
  local tag_count=0
  local -a tags=()

  if (( $# < 2 )); then
    return 64
  fi

  level=$1
  shift

  case ${level} in
    emergency | alert | critical | error | warning | notice | info | debug) ;;
    *) return 64 ;;
  esac

  if ! __bashlog_level_to_number "${level}"; then
    return 64
  fi
  level_number=${__bashlog_level_number}

  while (( $# > 0 )); do
    case $1 in
      --context)
        if (( context_seen || $# < 2 )); then
          return 64
        fi
        if __bashlog_context_resolve_active "$2"; then
          status=0
        else
          status=$?
        fi
        if (( status != 0 )); then
          return "${status}"
        fi
        context_index=${__bashlog_context_index}
        context_seen=1
        shift 2
        ;;
      --tag)
        if (( $# < 2 )) || ! __bashlog_tag_valid "$2"; then
          return 64
        fi
        tags[tag_count]=$2
        ((tag_count += 1))
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        return 64
        ;;
      *)
        break
        ;;
    esac
  done

  if (( $# == 0 )); then
    return 64
  fi

  if (( level_number > __bashlog_active_level )); then
    return 0
  fi

  format=$1
  shift

  if printf -v message -- "${format}" "$@" 2>/dev/null; then
    :
  else
    return 64
  fi

  if ! __bashlog_timestamp_acquire; then
    return 70
  fi
  timestamp=${__bashlog_timestamp_value}

  if (( context_seen )); then
    if ! __bashlog_redact_context "${context_index}" "${message}"; then
      __bashlog_emit_suppression_diagnostic "${context_index}"
      return 70
    fi
    message=${__bashlog_redacted_result}

    for ((index = 0; index < tag_count; index++)); do
      tag=${tags[index]}
      if ! __bashlog_redact_context "${context_index}" "${tag}"; then
        __bashlog_emit_suppression_diagnostic "${context_index}"
        return 70
      fi
      tags[index]=${__bashlog_redacted_result}
    done
  fi

  if (( tag_count > 0 )); then
    if ! __bashlog_render_record \
      "${level}" \
      "${timestamp}" \
      "${message}" \
      "${tags[@]}"; then
      if (( context_seen )); then
        __bashlog_emit_suppression_diagnostic "${context_index}"
      fi
      return 70
    fi
  else
    if ! __bashlog_render_record \
      "${level}" \
      "${timestamp}" \
      "${message}"; then
      if (( context_seen )); then
        __bashlog_emit_suppression_diagnostic "${context_index}"
      fi
      return 70
    fi
  fi
  candidate=${__bashlog_render_result}

  if (( context_seen )); then
    if ! __bashlog_context_verify "${context_index}" "${candidate}"; then
      __bashlog_emit_suppression_diagnostic "${context_index}"
      return 70
    fi
  fi

  if ! printf '%s\n' "${candidate}" >&2; then
    return 74
  fi

  return 0
}

bashlog_debug() {
  bashlog_log debug "$@"
}

bashlog_info() {
  bashlog_log info "$@"
}

bashlog_notice() {
  bashlog_log notice "$@"
}

bashlog_warning() {
  bashlog_log warning "$@"
}

bashlog_error() {
  bashlog_log error "$@"
}

bashlog_critical() {
  bashlog_log critical "$@"
}

bashlog_alert() {
  bashlog_log alert "$@"
}

bashlog_emergency() {
  bashlog_log emergency "$@"
}



set -euo pipefail

readonly UPLOAD_SARIF_USAGE_OVERVIEW=":file src/upload_sarif_to_defectdojo.bash\nauthor: CQPFC Team\n:brief a shell script to automate uploading SARIF results to DefectDojo\n:details\n This is a shell script that will iterate across a series of filenames\n passed in and upload the results to a DefectDojo instance.  This\n hope is to have one process generate SARIF results (e.g., Megalinter)\n so that this script can upload the results.\n\n There exist actions in the GitHub Actions Marketplace that will\n upload SARIF results to DefectDojo, such as:\n https://github.com/marketplace/actions/defectdojo-import-scan\n\n However, we want to be able to be able to upload results to\n an internal, non-Internet-accessible DefectDojo instance, potentially\n using an internal CI/CD system (e.g., a Jenkins instance).\n\n Configuration for the tool is expected to be provided by environment\n variables; this is to support clean integration with a CI/CD\n system that populates environment variables rather than using\n flags.  Additionally, the tool is able to use a configuration\n file (e.g., \`.env\`) that can provide values.\n\n The expected usage pattern is for a repository to include a\n configuration file with parameters like project name, whether\n or not to push results to Jira, etc. and environment variables to\n pass server details and authentication credentials.  It's possible\n to use all environment variables or all configuration files or\n some mix.\n\n The script supports passing multiple files to be uploaded, even\n if those files are in different locations or even associated with\n different projects. In situations like these, a configuration\n file for each location is supported.\n\n Several locations for configuration files are searched with the\n first one found being used:\n\n 1. current directory's uploadsarifdd.conf\n 2. current directory's .uploadsarifdd.conf\n 3. file's repo's uploadsarifdd.conf\n 4. file's repo's .uploadsarif.dd.conf\n 5. ~/uploadsarifdd.conf\n 6. ~/.uploadsarifdd.conf"

readonly UPLOAD_SARIF_USAGE_TEXT="--branch\t\t: see -b\n--config\t\t: see -c\n--date\t\t: see -d\n--dryrun\t\t: see -D\n--engagement\t\t: see -e\n--help\t\t: see -h\n--mime-type\t\t: see -m\n--product\t\t: see -p\n--scan-type\t\t: see -t\n--server\t\t: see -s\n--severity\t\t: see -S\n--url\t\t: see -u\n-b\t\t: set the branch to report\n-c\t\t: specify a configuration file\n-d\t\t: set the scan date\n-D\t\t: show curl command but don't send it\n-e\t\t: set the engagement\n-m\t\t: set the MIME type of the file\n-p\t\t: set the product\n-s\t\t: set the DefectDojo server\n-S\t\t: set the minimum severity to include\n-t\t\t: set the type of scan we're reporting\n-u\t\t: set the URL to the SCM"

if ! declare -F bashlog_info >/dev/null 2>&1; then
  __upload_sarif_source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  __upload_sarif_bashlog="${__upload_sarif_source_dir}/../vendor/bashlog.dev.bash"

  if [ ! -r "$__upload_sarif_bashlog" ]; then
    printf '%s\n' \
      'Missing vendor/bashlog.dev.bash; run make deps or execute a built artifact.' \
      >&2
    if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
      exit 1
    fi
    return 1
  fi

  source "$__upload_sarif_bashlog"
  unset __upload_sarif_source_dir __upload_sarif_bashlog
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}


is_git_repository() {
  command_exists git || return 1

  local target_dir
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1
}


git_branch() {
  command_exists git || return 1

  local target_dir branch sha
  target_dir="${1:-.}"

  if [ ! -d "$target_dir" ]; then
    target_dir="$(dirname -- "$target_dir")"
  fi

  is_git_repository "$target_dir" || return 1

  branch="$(git -C "$target_dir" branch --show-current 2>/dev/null || true)"
  if [ -n "$branch" ]; then
    printf '%s\n' "$branch"
    return 0
  fi

  branch="$(git -C "$target_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [ -n "$branch" ] && [ "$branch" != 'HEAD' ]; then
    printf '%s\n' "$branch"
    return 0
  fi

  sha="$(git -C "$target_dir" rev-parse --short HEAD 2>/dev/null || true)"
  [ -n "$sha" ] || return 1
  printf '%s\n' "$sha"
}


git_repository_root() {
  command_exists git || return 1

  local filename target_dir repo_root
  filename="${1:-.}"
  target_dir="$(dirname -- "$filename")"

  is_git_repository "$target_dir" || return 1

  repo_root="$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$repo_root" ] || return 1
  printf '%s\n' "$repo_root"
}



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

get_scan_date() {
  local filename
  filename="${1?No filename provided to get_scan_date}"
  echo "${DD_SCAN_DATE:-$(date +'%Y-%m-%d' -d "$(stat -L -c '%y' "$filename")")}"
}

get_scm_url() {
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


get_commit_hash() {
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



die() {
  printf "ERROR %s in %s AT LINE %s\n" "$?" "${BASH_SOURCE[0]}" "${BASH_LINENO[0]}" 1>&2

  local i=0
  local FRAMES=${#BASH_LINENO[@]}

  for ((i = FRAMES - 2; i >= 0; i--)); do
    printf "  File \"%s\", line %s, in %s\n" "${BASH_SOURCE[i + 1]}" "${BASH_LINENO[i]}" "${FUNCNAME[i + 1]}"
    sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i + 1]}"
  done
  exit 1
}

display_usage() {
  printf "Overview\n%b\n" "$UPLOAD_SARIF_USAGE_OVERVIEW"
  printf "\nUsage:\n%b\n" "$UPLOAD_SARIF_USAGE_TEXT"
}



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
  source "$configuration_file"
  set +o allexport

  for variable in "${variables[@]}"; do
    if [ -n "${was_set[$variable]:-}" ]; then
      printf -v "$variable" '%s' "${values[$variable]}"
      export "${variable?}"
    fi
  done
}

process_scan_file() {
  local filename="$1"
  local -a form_values=()
  local -a configuration_sources=()
  local -a curl_command=()
  local configuration_file=""
  local configuration_candidate
  local repo_root
  local scm_url
  local form_value

  if [ ! -e "$filename" ]; then
    if [[ "$filename" == *[\*\?\[]* ]]; then
      bashlog_info 'No files matched pattern: %s' "$filename"
      exit 0
    fi

    bashlog_error 'file not found: %s' "$filename"
    exit 1
  fi

  if [ ! -f "$filename" ]; then
    bashlog_error 'not a regular file: %s' "$filename"
    exit 1
  fi
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

  configuration_file=""
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
  curl_command=(curl -X "${METHOD:-POST}" "${DD_SERVER_PROTO:-https}://${DD_SERVER_HOST}${DD_SERVER_PATH:-/api/v2/import-scan/}" -H "accept: application/json" -H "Authorization: Token ${DD_TOKEN}")

  for form_value in "${form_values[@]}"; do
    curl_command+=("-F" "$form_value")
  done

  if [ "${DRYRUN:-0}" = "1" ]; then
    print_curl_command_redacted curl_command
    exit 0
  fi

  "${curl_command[@]}"

}


main() {

  trap die ERR


  declare -a configuration_sources

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

if [[ "$0" == "${BASH_SOURCE[0]}" ]] && [ "$(type -t "main")" = "function" ]; then
  main "$@"
fi
