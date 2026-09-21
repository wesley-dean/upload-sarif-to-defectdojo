#!/usr/bin/env bats
load test_helper

setup() {
  setup_common
  REPO="${TEST_TMPDIR}/repo"
  create_git_repo "$REPO"
  create_sarif "${REPO}/reports/test.sarif"
  commit_all "$REPO"
}
teardown() { teardown_common; }

@test "file paths are recognized inside a Git repository" {
  run bash -c 'source "$1"; is_git_repository "$2"' _ "$SCRIPT" "${REPO}/reports/test.sarif"
  [ "$status" -eq 0 ]
}

@test "git_repository_root resolves from a file path" {
  run bash -c 'source "$1"; git_repository_root "$2"' _ "$SCRIPT" "${REPO}/reports/test.sarif"
  [ "$status" -eq 0 ]
  [ "$output" = "$REPO" ]
}

@test "git_branch returns the symbolic branch" {
  expected="$(git -C "$REPO" branch --show-current)"
  run bash -c 'source "$1"; git_branch "$2"' _ "$SCRIPT" "${REPO}/reports/test.sarif"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "git_branch falls back to short SHA when detached" {
  full="$(git -C "$REPO" rev-parse HEAD)"
  expected="$(git -C "$REPO" rev-parse --short HEAD)"
  git -C "$REPO" checkout -q "$full"
  run bash -c 'source "$1"; git_branch "$2"' _ "$SCRIPT" "${REPO}/reports/test.sarif"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "get_commit_hash returns HEAD" {
  expected="$(git -C "$REPO" rev-parse HEAD)"
  run bash -c 'source "$1"; get_commit_hash "$2"' _ "$SCRIPT" "${REPO}/reports/test.sarif"
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}

@test "get_scm_url strips credentials and trailing .git" {
  remote_url='https://'
  remote_url+='fixture-user:fixture-value'
  remote_url+='@github.com/example/project.git'
  git -C "$REPO" remote add origin "$remote_url"
  run bash -c 'source "$1"; get_scm_url "$2"' _ "$SCRIPT" "${REPO}/reports/test.sarif"
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/example/project" ]
}
