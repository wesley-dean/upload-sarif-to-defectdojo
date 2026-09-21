setup_common() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  export PROJECT_ROOT
  SCRIPT="${PROJECT_ROOT}/upload_sarif_to_defectdojo.bash"
  export SCRIPT
  TEST_TMPDIR="$(mktemp -d)"
  export TEST_TMPDIR
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "$HOME"
}

teardown_common() {
  rm -rf "$TEST_TMPDIR"
}

create_sarif() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' '{}' > "$path"
}

create_git_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name Test
}

commit_all() {
  local repo="$1"
  git -C "$repo" add .
  git -C "$repo" commit -qm test
}

install_fake_curl() {
  local bin_dir="${TEST_TMPDIR}/bin"
  mkdir -p "$bin_dir"
  cat > "${bin_dir}/curl" <<'SCRIPT'
#!/usr/bin/env bash
: "${CURL_CAPTURE:?}"
printf '%s\n' "$@" >> "$CURL_CAPTURE"
printf '%s\n' '--CALL-END--' >> "$CURL_CAPTURE"
SCRIPT
  chmod +x "${bin_dir}/curl"
  export PATH="${bin_dir}:${PATH}"
}
