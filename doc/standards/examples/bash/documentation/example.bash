#!/usr/bin/env bash
# shellcheck shell=bash
## @file standards/examples/bash/documentation/example.bash
## @brief Demonstrates the Bash documentation standard.
## @details
## This non-normative example shows representative file, variable, and function
## documentation using the maintained Bash Doxygen dialect.  The example keeps
## stream behavior, return status, side effects, and examples explicit so a
## caller does not need to infer the contract from the implementation.

## @var EXAMPLE_DEFAULT_PREFIX
## @brief Prefix used when formatting normalized example names.
## @details
## The value is immutable for the lifetime of this process and participates in
## the output contract of `format_name()`.
readonly EXAMPLE_DEFAULT_PREFIX='item'

## @fn normalize_name()
## @brief Normalizes a caller-supplied example name.
## @details
## Converts ASCII uppercase letters to lowercase and rejects empty input.  The
## function does not modify caller-visible shell state other than writing the
## normalized value to STDOUT on success.
##
## @param name Name supplied by the caller.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## The normalized name is written as one line when validation succeeds.
## @par STDERR
## A diagnostic is written when `name` is empty.
##
## @returns A single newline-terminated normalized string on success.
##
## @retval 0 The name was valid and was normalized successfully.
## @retval 64 The caller supplied an empty name.
##
## @par Examples
## @code
## normalized="$(normalize_name 'Demo')"
## @endcode
normalize_name() {
  local name=${1-}

  if [[ -z ${name} ]]; then
    printf '%s\n' 'name must not be empty' >&2
    return 64
  fi

  printf '%s\n' "${name,,}"
}

## @fn format_name()
## @brief Formats a normalized name for display.
## @details
## Normalizes the supplied name through `normalize_name()` and prefixes the
## resulting value with `EXAMPLE_DEFAULT_PREFIX`.  Validation failure from the
## normalization step is propagated unchanged.
##
## @param name Name supplied by the caller.
##
## @par STDIN
## Nothing is read from STDIN.
## @par STDOUT
## One formatted name is written when normalization succeeds.
## @par STDERR
## Diagnostics produced by `normalize_name()` may be propagated unchanged.
##
## @returns A single newline-terminated formatted string on success.
##
## @retval 0 The supplied name was normalized and formatted successfully.
## @note Non-zero statuses from `normalize_name()` may be propagated unchanged.
##
## @par Examples
## @code
## formatted="$(format_name 'Demo')"
## @endcode
format_name() {
  local name=${1-}
  local normalized

  normalized="$(normalize_name "${name}")" || return $?
  printf '%s:%s\n' "${EXAMPLE_DEFAULT_PREFIX}" "${normalized}"
}

## @fn is_valid_name()
## @brief Determines whether an example name is valid.
## @details
## Treats a non-empty string containing only ASCII letters, digits, underscores,
## and hyphens as valid.  The result is communicated exclusively through the
## function status and no value is emitted to STDOUT.
##
## @param name Name to inspect.
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
## @retval 0 The supplied name is valid.
## @retval 1 The supplied name is invalid.
##
## @par Examples
## @code
## if is_valid_name 'demo-1'; then
##   printf '%s\n' 'valid'
## fi
## @endcode
is_valid_name() {
  local name=${1-}

  [[ ${name} =~ ^[[:alnum:]_-]+$ ]]
}
