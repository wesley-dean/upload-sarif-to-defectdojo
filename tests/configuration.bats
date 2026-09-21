#!/usr/bin/env bats
load test_helper

setup() {
  setup_common
  FILE="${TEST_TMPDIR}/repo/report.sarif"
  create_sarif "$FILE"
}
teardown() { teardown_common; }

@test "explicit config supplies required settings" {
  cat > "${TEST_TMPDIR}/explicit.conf" <<'CONFIG'
DD_TOKEN=config-token
DD_PRODUCT=config-product
DD_SERVER_HOST=config.example
CONFIG
  run "$SCRIPT" --dryrun --config "${TEST_TMPDIR}/explicit.conf" "$FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"https://config.example/api/v2/import-scan/"* ]]
  [[ "$output" == *"product_name=config-product"* ]]
  [[ "$output" != *"config-token"* ]]
}

@test "missing explicit config fails instead of falling back" {
  cat > "${HOME}/uploadsarifdd.conf" <<'CONFIG'
DD_TOKEN=home-token
DD_PRODUCT=home-product
DD_SERVER_HOST=home.example
CONFIG
  run "$SCRIPT" --dryrun --config "${TEST_TMPDIR}/missing.conf" "$FILE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"No readable explicit configuration file was found"* ]]
}

@test "environment values override configuration" {
  cat > "${TEST_TMPDIR}/explicit.conf" <<'CONFIG'
DD_TOKEN=config-token
DD_PRODUCT=config-product
DD_SERVER_HOST=config.example
DD_ENGAGEMENT=config-engagement
CONFIG
  run env DD_TOKEN=env-token DD_PRODUCT=env-product DD_SERVER_HOST=env.example \
    "$SCRIPT" --dryrun --config "${TEST_TMPDIR}/explicit.conf" "$FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"https://env.example/api/v2/import-scan/"* ]]
  [[ "$output" == *"product_name=env-product"* ]]
  [[ "$output" == *"engagement_name=config-engagement"* ]]
  [[ "$output" != *"env-token"* ]]
  [[ "$output" != *"config-token"* ]]
}

@test "CLI values override environment and configuration" {
  cat > "${TEST_TMPDIR}/explicit.conf" <<'CONFIG'
DD_TOKEN=config-token
DD_PRODUCT=config-product
DD_SERVER_HOST=config.example
CONFIG
  run env DD_TOKEN=env-token DD_PRODUCT=env-product DD_SERVER_HOST=env.example \
    "$SCRIPT" --dryrun --config "${TEST_TMPDIR}/explicit.conf" \
    --product cli-product --server cli.example "$FILE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"https://cli.example/api/v2/import-scan/"* ]]
  [[ "$output" == *"product_name=cli-product"* ]]
}

@test "repository-root config is discovered for nested scan files" {
  REPO="${TEST_TMPDIR}/repo"
  create_git_repo "$REPO"
  create_sarif "${REPO}/reports/test.sarif"
  cat > "${REPO}/uploadsarifdd.conf" <<'CONFIG'
DD_TOKEN=repo-token
DD_PRODUCT=repo-product
DD_SERVER_HOST=repo.example
CONFIG
  commit_all "$REPO"
  run "$SCRIPT" --dryrun "${REPO}/reports/test.sarif"
  [ "$status" -eq 0 ]
  [[ "$output" == *"https://repo.example/api/v2/import-scan/"* ]]
  [[ "$output" == *"product_name=repo-product"* ]]
}
