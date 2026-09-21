#!/usr/bin/env bats
load test_helper

setup() {
  setup_common
  FILE="${TEST_TMPDIR}/repo/report.sarif"
  create_sarif "$FILE"
  export CURL_CAPTURE="${TEST_TMPDIR}/curl.args"
  install_fake_curl
}
teardown() { teardown_common; }

@test "dry run redacts token and does not execute curl" {
  run env DD_TOKEN=supersecret DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    "$SCRIPT" --dryrun "$FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"REDACTED"* ]]
  [[ "$output" != *"supersecret"* ]]
  [ ! -e "$CURL_CAPTURE" ]
}

@test "curl receives -F and values as separate argv entries" {
  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    CURL_CAPTURE="$CURL_CAPTURE" PATH="$PATH" "$SCRIPT" "$FILE"
  [ "$status" -eq 0 ]
  run awk 'prev=="-F" && $0=="product_name=product" {found=1} {prev=$0} END{exit found?0:1}' "$CURL_CAPTURE"
  [ "$status" -eq 0 ]
}

@test "default endpoint and fields are constructed" {
  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    CURL_CAPTURE="$CURL_CAPTURE" PATH="$PATH" "$SCRIPT" "$FILE"
  [ "$status" -eq 0 ]
  grep -Fxq 'https://dojo.example/api/v2/import-scan/' "$CURL_CAPTURE"
  grep -Fxq 'active=true' "$CURL_CAPTURE"
  grep -Fxq 'minimum_severity=Info' "$CURL_CAPTURE"
  grep -Fxq 'verified=true' "$CURL_CAPTURE"
}

@test "Git metadata is attached and SCM credentials are removed" {
  REPO="${TEST_TMPDIR}/repo"
  create_git_repo "$REPO"
  git -C "$REPO" remote add origin 'https://user:password@github.com/example/repo.git'
  commit_all "$REPO"
  expected_commit="$(git -C "$REPO" rev-parse HEAD)"
  expected_branch="$(git -C "$REPO" branch --show-current)"
  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    CURL_CAPTURE="$CURL_CAPTURE" PATH="$PATH" "$SCRIPT" "$FILE"
  [ "$status" -eq 0 ]
  grep -Fxq "branch=${expected_branch}" "$CURL_CAPTURE"
  grep -Fxq "commit_hash=${expected_commit}" "$CURL_CAPTURE"
  grep -Fxq 'source_code_management_uri=https://github.com/example/repo' "$CURL_CAPTURE"
  ! grep -q 'password' "$CURL_CAPTURE"
}
