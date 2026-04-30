#!/usr/bin/env bats
# Core tests: subject-only / trivial flag combinations and skip-pattern matching.

load helpers

# ---------------------------------------------------------------------------
# Subject-only / trivial flag (4 cases)
# ---------------------------------------------------------------------------

@test "single-line commit without GITGIT_TRIVIAL_OK fails with missing-body" {
  local file
  file=$(write_fixture "single.txt" "Expose session endpoint")

  export GITGIT_TRIVIAL_OK=0
  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-body"* ]]
}

@test "single-line commit with GITGIT_TRIVIAL_OK=1 passes" {
  local file
  file=$(write_fixture "trivial.txt" "Expose session endpoint")

  export GITGIT_TRIVIAL_OK=1
  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "multi-line commit does not require GITGIT_TRIVIAL_OK" {
  use_trailers "$VALID_TRAILERS"
  local file
  file=$(write_fixture "multi.txt" "$VALID_BODY_TEMPLATE")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "empty file exits 2 (non-blocking skip)" {
  local file
  file=$(write_fixture "empty.txt" "")

  run invoke_validator "$file"
  [ "$status" -eq 2 ]
  [[ "$output" == *"empty-message"* ]]
}

# ---------------------------------------------------------------------------
# Skip patterns (5 cases)
# ---------------------------------------------------------------------------

@test "Merge commit subject is silently skipped" {
  local file
  file=$(write_fixture "merge.txt" "Merge branch 'feature/foo' into main")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "Revert commit subject is silently skipped" {
  local file
  file=$(write_fixture "revert.txt" "Revert \"Expose session endpoint\"

This reverts commit abc1234.")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "fixup! commit subject is silently skipped" {
  local file
  file=$(write_fixture "fixup.txt" "fixup! Expose session endpoint")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "squash! commit subject is silently skipped" {
  local file
  file=$(write_fixture "squash.txt" "squash! Expose session endpoint")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "amend! commit subject is silently skipped" {
  local file
  file=$(write_fixture "amend.txt" "amend! Expose session endpoint")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}
