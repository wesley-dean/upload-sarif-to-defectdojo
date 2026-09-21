#!/usr/bin/env bats
load test_helper

setup() {
  setup_common
  FILE="${TEST_TMPDIR}/report.sarif"
  create_sarif "$FILE"
}
teardown() { teardown_common; }

@test "help succeeds without DefectDojo configuration" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
}

@test "explicitly missing file fails" {
  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    "$SCRIPT" --dryrun "${TEST_TMPDIR}/missing.sarif"
  [ "$status" -ne 0 ]
  [[ "$output" == *"file not found"* ]]
}

@test "unmatched glob is a successful no-op" {
  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    "$SCRIPT" --dryrun "${TEST_TMPDIR}/*.sarif.missing"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No files matched pattern"* ]]
}

@test "directory input is rejected" {
  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    "$SCRIPT" --dryrun "$TEST_TMPDIR"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a regular file"* ]]
}

@test "unset required values have controlled diagnostics" {
  run env -u DD_PRODUCT DD_TOKEN=token DD_SERVER_HOST=dojo.example \
    "$SCRIPT" --dryrun "$FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No value for DD_PRODUCT provided"* ]]

  run env -u DD_SERVER_HOST DD_TOKEN=token DD_PRODUCT=product \
    "$SCRIPT" --dryrun "$FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No value for DD_SERVER_HOST provided"* ]]
}
