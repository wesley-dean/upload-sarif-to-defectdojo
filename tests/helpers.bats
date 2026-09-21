#!/usr/bin/env bats
load test_helper

setup() { setup_common; }
teardown() { teardown_common; }

@test "get_scan_type recognizes SARIF" {
  run bash -c 'source "$1"; get_scan_type report.sarif' _ "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "SARIF" ]
}

@test "get_scan_type rejects unknown suffixes" {
  run bash -c 'source "$1"; get_scan_type report.json' _ "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "get_mime_type recognizes SARIF" {
  run bash -c 'source "$1"; get_mime_type report.sarif' _ "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "application/SARIF" ]
}

@test "get_scan_date honors DD_SCAN_DATE" {
  run bash -c 'source "$1"; DD_SCAN_DATE=2026-09-20 get_scan_date missing.sarif' _ "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "2026-09-20" ]
}
