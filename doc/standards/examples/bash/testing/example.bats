#!/usr/bin/env bats
# Non-normative example: use one dynamically registered Bats suite to exercise
# several behaviorally equivalent command-line artifacts.
#
# Run from the repository root, for example:
#
#   bats --formatter tap \
#     --report-formatter junit \
#     --output test-results/example \
#     doc/standards/examples/bash/testing/example.bats

check_version() {
  local label=$1
  local relative_executable=$2
  local project_root=${PROJECT_ROOT:-$PWD}

  run "$project_root/$relative_executable" --version

  [ "$status" -eq 0 ]
  [[ "$output" == *"example-tool"* ]]
}

check_invalid_input() {
  local label=$1
  local relative_executable=$2
  local project_root=${PROJECT_ROOT:-$PWD}

  run "$project_root/$relative_executable" --definitely-invalid

  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid"* ]]
}

register_artifact() {
  local label=$1
  local relative_executable=$2

  bats_test_function \
    --description "${label}: reports version" \
    -- check_version "$label" "$relative_executable"

  bats_test_function \
    --description "${label}: rejects invalid input" \
    -- check_invalid_input "$label" "$relative_executable"
}

register_artifact source "example-tool"
register_artifact ordinary "dist/example-tool"
register_artifact minified "dist/example-tool.min"
