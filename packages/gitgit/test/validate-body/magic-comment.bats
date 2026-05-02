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

@test "vsd-skip on a UI-touched commit fails with vsd-skip-ui-touch" {
  # Stage a SwiftUI file so the UI-touch heuristic fires.
  set_staged_blob "Sources/Card.swift" "import SwiftUI

struct Card: View { var body: some View { Text(\"hi\") } }"
  export GIT_SHIM_DIFF_CACHED_OUTPUT="Sources/Card.swift"

  local body
  body="$(cat <<'MSG'
Tighten resident card layout

# vsd-skip: visual evidence lands in INSPECT
MSG
)"
  local file
  file=$(write_fixture "vsd-skip-ui.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"vsd-skip-ui-touch"* ]]
  [[ "$output" == *"Sources/Card.swift"* ]]
}

@test "vsd-skip on a backend-only commit still passes (heuristic does not fire)" {
  export GIT_SHIM_DIFF_CACHED_OUTPUT="lib/app_state.rb"

  local body
  body="$(cat <<'MSG'
Expose session endpoint

# vsd-skip: one-line hotfix pushed under time pressure
MSG
)"
  local file
  file=$(write_fixture "vsd-skip-backend.txt" "$body")

  export HOME="$TMPDIR_TEST"
  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "vsd-skip is rejected outright under GITGIT_AUTONOMOUS=1" {
  export GIT_SHIM_DIFF_CACHED_OUTPUT="lib/app_state.rb"
  export GITGIT_AUTONOMOUS=1

  local body
  body="$(cat <<'MSG'
Expose session endpoint

# vsd-skip: one-line hotfix pushed under time pressure
MSG
)"
  local file
  file=$(write_fixture "vsd-skip-autonomous.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"vsd-skip-autonomous"* ]]
}
