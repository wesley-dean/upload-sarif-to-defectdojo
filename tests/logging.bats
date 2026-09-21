#!/usr/bin/env bats
load test_helper

setup() {
  setup_common
}

teardown() {
  teardown_common
}

@test "public artifact embeds bashlog" {
  run bash -c 'source "$1"; type -t bashlog_info' _ "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$output" = "function" ]
}

@test "operational errors use bashlog on standard error" {
  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    "$SCRIPT" --dryrun "${TEST_TMPDIR}/missing.sarif"
  [ "$status" -ne 0 ]
  [[ "$output" == *'level=error'* ]]
  [[ "$output" == *'file not found:'* ]]
}

@test "operational logging does not invoke logger" {
  mkdir -p "${TEST_TMPDIR}/bin"
  cat > "${TEST_TMPDIR}/bin/logger" <<'LOGGER'
#!/usr/bin/env bash
: "${LOGGER_CALLED:?}"
printf '%s\n' called > "$LOGGER_CALLED"
LOGGER
  chmod +x "${TEST_TMPDIR}/bin/logger"
  export LOGGER_CALLED="${TEST_TMPDIR}/logger.called"

  run env DD_TOKEN=token DD_PRODUCT=product DD_SERVER_HOST=dojo.example \
    LOGGER_CALLED="$LOGGER_CALLED" PATH="${TEST_TMPDIR}/bin:${PATH}" \
    "$SCRIPT" --dryrun "${TEST_TMPDIR}/missing.sarif"

  [ "$status" -ne 0 ]
  [ ! -e "$LOGGER_CALLED" ]
}
