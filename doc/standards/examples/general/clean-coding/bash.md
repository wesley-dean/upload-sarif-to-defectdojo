# Clean Coding Examples for Bash

## Purpose

This document provides Bash examples illustrating the
[Clean Coding Standard](../../../general/clean-coding-standard.md).

The examples are illustrative rather than normative.  They demonstrate ways the
general principles may be expressed in Bash, but they do not replace a Bash-specific
coding standard or repository-specific governance.

## Functions Should Do One Thing

A function with several independent responsibilities can be difficult to understand
and test:

```bash
prepare_release() {
  validate_configuration
  tar -czf "$archive" "$build_dir"
  sha256sum "$archive" >"$archive.sha256"
  curl --fail --upload-file "$archive" "$release_url"
}
```

The same workflow can expose its responsibilities more clearly:

```bash
validate_release() {
  validate_configuration
}

build_release_archive() {
  tar -czf "$archive" "$build_dir"
}

generate_release_checksum() {
  sha256sum "$archive" >"$archive.sha256"
}

publish_release() {
  curl --fail --upload-file "$archive" "$release_url"
}

prepare_release() {
  validate_release
  build_release_archive
  generate_release_checksum
  publish_release
}
```

`prepare_release` still coordinates several operations, but its responsibility is
now the release workflow.  Lower-level mechanics are delegated to functions with
more specific responsibilities.

## Separate Commands from Queries

A query should avoid changing observable state unexpectedly.

For example, this function appears to answer a question but also creates a file:

```bash
configuration_exists() {
  if [[ ! -f $config_file ]]; then
    install_default_configuration
  fi

  [[ -f $config_file ]]
}
```

Separating the observation from the mutation makes the behavior easier to reason
about:

```bash
configuration_exists() {
  [[ -f $config_file ]]
}

install_default_configuration() {
  cp "$default_config" "$config_file"
}

if ! configuration_exists; then
  install_default_configuration
fi
```

The command may still return a Bash exit status indicating success or failure.  The
important distinction is that a caller does not need to invoke an apparently
observational function in order to trigger a state change.

## Maintain One Level of Abstraction

Mixing workflow decisions with low-level mechanics can obscure the primary flow:

```bash
publish_artifacts() {
  validate_release

  mkdir -p "$output_dir"
  sha256sum "$artifact" >"$output_dir/$artifact_name.sha256"
  printf '%s\n' "$metadata" >"$output_dir/metadata.json"
  curl --fail --upload-file "$artifact" "$release_url"
}
```

A higher-level function can instead express the workflow:

```bash
publish_artifacts() {
  validate_release
  prepare_release_metadata
  generate_release_checksums
  upload_release_artifacts
}
```

The lower-level file, hashing, serialization, and network operations still exist,
but the orchestration function communicates why they are being performed.

## Make Side Effects Explicit

A function named like a query should not unexpectedly change global state:

```bash
get_repository_root() {
  REPOSITORY_ROOT=$(git rev-parse --show-toplevel)
}
```

A function that prints the value can make the data flow more visible:

```bash
repository_root() {
  git rev-parse --show-toplevel
}

repository_root=$(repository_root)
```

If modifying shared state is intentional, naming can make that purpose visible:

```bash
set_repository_root() {
  REPOSITORY_ROOT=$(git rev-parse --show-toplevel)
}
```

## Use Descriptive Names

Generic names force the reader to inspect implementation details:

```bash
process() {
  sha256sum "$1"
}
```

A purpose-oriented name communicates more information:

```bash
calculate_checksum() {
  sha256sum "$1"
}
```

The same principle applies to variables.  Prefer names that communicate the role of
a value when that role is not already obvious from a very small local context.

## Prefer Explicit Behavior

Dense expressions can save lines while increasing the amount of reasoning required
from the reader:

```bash
[[ -f $config && -r $config ]] && source "$config" || return 1
```

A more explicit form exposes the decision points:

```bash
if [[ ! -f $config ]]; then
  return 1
fi

if [[ ! -r $config ]]; then
  return 1
fi

source "$config"
```

Whether `source` is appropriate is a separate security and interface decision.  The
example illustrates control-flow clarity rather than recommending executable
configuration files.

## Keep Interfaces Focused

Boolean-like positional arguments can be difficult to interpret at the call site:

```bash
render_report "$input" true false
```

Separate operations or explicit options can make intent clearer:

```bash
render_summary_report "$input"
```

or, when one interface genuinely represents a cohesive operation:

```bash
render_report --format summary --input "$input"
```

The goal is not to eliminate parameters mechanically.  The interface should make
the caller's intent understandable without requiring the reader to remember what
`true` and `false` mean in each position.

## Keep Control Flow Understandable

Deep nesting can hide the primary path:

```bash
publish_if_valid() {
  if [[ -f $artifact ]]; then
    if verify_checksum "$artifact"; then
      if release_exists; then
        upload_artifact "$artifact"
      fi
    fi
  fi
}
```

Early returns can keep the successful path visible:

```bash
publish_if_valid() {
  [[ -f $artifact ]] || return 1
  verify_checksum "$artifact" || return 1
  release_exists || return 1

  upload_artifact "$artifact"
}
```

This form is not universally preferable, but it illustrates the standard's guidance
to minimize unnecessary nesting and keep major decisions visible.

## Avoid Unnecessary Duplication

Duplicating the same policy in several places creates multiple sources of truth:

```bash
validate_build_name() {
  [[ $1 =~ ^[a-z0-9-]+$ ]]
}

validate_release_name() {
  [[ $1 =~ ^[a-z0-9-]+$ ]]
}
```

If the two functions genuinely enforce the same naming rule, a shared abstraction
can make that policy explicit:

```bash
validate_artifact_name() {
  [[ $1 =~ ^[a-z0-9-]+$ ]]
}

validate_build_name() {
  validate_artifact_name "$1"
}

validate_release_name() {
  validate_artifact_name "$1"
}
```

If build names and release names only happen to use the same expression today but
represent different policies, keeping them separate may be the better design.  The
important question is whether the duplicated code represents duplicated knowledge.

## Comments Explain Why

A comment that restates the next command adds little information:

```bash
# Create the directory.
mkdir -p "$cache_dir"
```

A comment can instead preserve a constraint that the code alone does not explain:

```bash
# Keep the cache beneath the workspace because CI runners discard all other
# writable paths between jobs.
mkdir -p "$cache_dir"
```

The second comment records reasoning a future maintainer might otherwise have to
rediscover.

## Errors Are Part of the Interface

Discarding diagnostic context can make a failure difficult to investigate:

```bash
curl --fail --silent "$url" -o "$destination" 2>/dev/null || return 1
```

Preserving or adding useful context makes the failure more actionable:

```bash
download_file() {
  local url=$1
  local destination=$2

  if ! curl --fail --show-error --silent "$url" -o "$destination"; then
    printf 'error: failed to download %s\n' "$url" >&2
    return 1
  fi
}
```

The exact diagnostic policy belongs to the repository and its interfaces.  The
example illustrates the principle that failures should be deliberate and should
retain enough context to understand what operation failed.

## Review Questions for Bash

When applying the general review questions to Bash, it may be useful to ask:

- Does the function have one identifiable responsibility?
- Does a function that looks observational modify files, globals, environment, or
  process state?
- Are workflow functions separated from shell and utility mechanics where doing so
  improves readability?
- Can the purpose of functions and important variables be understood from their
  names?
- Is the main execution path visible without tracing deeply nested conditionals?
- Are exit statuses and diagnostics handled deliberately?
- Does shared helper code represent a genuinely shared rule rather than merely
  similar-looking commands?

These questions remain heuristics.  Repository governance and any Bash-specific
standard take precedence where they establish a more specific rule.
