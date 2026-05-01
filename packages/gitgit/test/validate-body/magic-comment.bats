#!/usr/bin/env bats
# Magic-comment opt-out: "# vsd-skip: <reason>" in the commit message.

load helpers

# ---------------------------------------------------------------------------
# Magic-comment cases (2 cases)
# ---------------------------------------------------------------------------

@test "vsd-skip with a reason opts out and returns exit 0" {
  # A commit that would otherwise fail (no body) is allowed via vsd-skip.
  local body
  body="$(cat <<'MSG'
Expose session endpoint

# vsd-skip: one-line hotfix pushed under time pressure
MSG
)"
  local file
  file=$(write_fixture "vsd-skip-ok.txt" "$body")

  # Redirect HOME so the skip log goes to the temp dir.
  export HOME="$TMPDIR_TEST"
  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "bare vsd-skip without reason fails with invalid-skip" {
  local body
  body="$(cat <<'MSG'
Expose session endpoint

# vsd-skip:
MSG
)"
  local file
  file=$(write_fixture "vsd-skip-no-reason.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid-skip"* ]]
}
