#!/usr/bin/awk -f
## @file standards/examples/awk/documentation/example.awk
## @brief Demonstrates the AWK documentation standard.
## @details
## This non-normative example shows representative file, variable, function,
## BEGIN-rule, ordinary-rule, and END-rule documentation.  The program reads
## comma-separated name/value records, normalizes accepted names, and emits a
## final processing summary.

## @var record_count
## @brief Number of accepted input records.
## @details
## This global counter is initialized in `initialize` and incremented only after
## a record passes validation and is emitted.

## @var rejected_count
## @brief Number of rejected input records.
## @details
## This global counter is initialized in `initialize` and incremented whenever a
## record fails the expected two-field input contract.

## @fn normalize_name(value)
## @brief Normalizes an example name.
## @details
## Converts ASCII uppercase letters to lowercase and replaces spaces with
## underscores.  The function has no stream side effects and does not modify
## global state.
##
## @param value Name to normalize.
## @local result Scratch copy used while normalizing the value.
##
## @par STDIN
## Nothing is read directly from STDIN.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns The normalized name string.
##
## @par Examples
## @code
## normalized = normalize_name("Demo Name")
## @endcode
function normalize_name(value,    result) {
  result = tolower(value)
  gsub(/[[:space:]]+/, "_", result)
  return result
}

## @fn is_valid_record()
## @brief Determines whether the current input record has the expected shape.
## @details
## Reads the current record context and considers a record valid only when AWK
## has split it into exactly two fields.  The function does not modify `$0`,
## `NF`, or any global state.
##
## @par STDIN
## Nothing is read directly from STDIN; the current AWK record is inspected.
## @par STDOUT
## Nothing is written to STDOUT.
## @par STDERR
## Nothing is written to STDERR.
##
## @returns A numeric truth value.
## @retval 1 The current record contains exactly two fields.
## @retval 0 The current record does not contain exactly two fields.
##
## @par Examples
## @code
## if (is_valid_record()) {
##   # process the current record
## }
## @endcode
function is_valid_record() {
  return (NF == 2)
}

## @rule initialize
## @brief Initializes parsing configuration and global counters.
## @details
## Establishes comma-separated input and output before the first record is
## processed.  The rule also initializes the counters used by later rules and
## the final summary.
BEGIN {
  FS = ","
  OFS = ","
  record_count = 0
  rejected_count = 0
}

## @rule comment_lines
## @brief Ignores comment records.
## @details
## Matches records whose first non-space character is `#`.  Comment records do
## not affect accepted or rejected counts.
/^[[:space:]]*#/ {
  next
}

## @rule invalid_records
## @brief Rejects records that do not contain exactly two fields.
## @details
## Increments `rejected_count`, writes a diagnostic containing the source record
## number, and prevents invalid input from reaching the accepted-record rule.
!is_valid_record() {
  rejected_count++
  printf "invalid record at line %d\n", FNR > "/dev/stderr"
  next
}

## @rule accepted_records
## @brief Normalizes and emits accepted records.
## @details
## Normalizes the first field, preserves the second field as supplied, increments
## `record_count`, and writes one comma-separated output record.
is_valid_record() {
  record_count++
  print normalize_name($1), $2
}

## @rule summarize
## @brief Emits the final processing summary.
## @details
## Writes accepted and rejected totals after input processing completes.  The
## summary is emitted even when no ordinary input records were accepted.
END {
  printf "accepted=%d rejected=%d\n", record_count, rejected_count
}
