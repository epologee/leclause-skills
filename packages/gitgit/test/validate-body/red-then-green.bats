#!/usr/bin/env bats
# Red-then-green trailer: valid values, absent trailer, bare n/a without rationale.

load helpers

# ---------------------------------------------------------------------------
# Helper: body with a given RTG value
# ---------------------------------------------------------------------------

_body_with_rtg() {
  local rtg_value="$1"
  cat <<MSG
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts and stops.

Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: ${rtg_value}
MSG
}

# ---------------------------------------------------------------------------
# Red-then-green cases (3 cases)
# ---------------------------------------------------------------------------

@test "Red-then-green: yes is accepted" {
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Slice: handler + service + spec"$'\n'"Red-then-green: yes"

  local file
  file=$(write_fixture "rtg-yes.txt" "$(_body_with_rtg "yes")")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "Red-then-green: n/a with long rationale is accepted" {
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Slice: handler + service + spec"$'\n'"Red-then-green: n/a (adding log line only, no logic change)"

  local file
  file=$(write_fixture "rtg-na-rationale.txt" "$(_body_with_rtg "n/a (adding log line only, no logic change)")")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "Red-then-green: bare n/a without rationale fails" {
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Slice: handler + service + spec"$'\n'"Red-then-green: n/a"

  local file
  file=$(write_fixture "rtg-bare-na.txt" "$(_body_with_rtg "n/a")")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-red-then-green"* ]]
}

# ---------------------------------------------------------------------------
# Fix 2: migration-only and spec-only RTG exemption
# ---------------------------------------------------------------------------

@test "Slice: migration-only does not require Red-then-green (Fix 2)" {
  use_trailers "Slice: migration-only"
  local body
  body="$(cat <<'MSG'
Add NOT NULL constraint to sessions.user_id

The column lacked the constraint in the original migration.
Backfill confirmed no nulls exist in production before this runs.

Slice: migration-only
MSG
)"
  local file
  file=$(write_fixture "rtg-migration-only.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Spec-path form (insight 1): the trailer names the spec file that was seen
# red, and that path must be in the staged diff so the claim is anchored to
# the commit instead of pointing at any file in the repo.
# ---------------------------------------------------------------------------

@test "Red-then-green: spec-path present in staged diff is accepted" {
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  export GIT_SHIM_DIFF_CACHED_OUTPUT="spec/services/session_spec.rb"$'\n'"app/services/session.rb"
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Slice: handler + service + spec"$'\n'"Red-then-green: spec/services/session_spec.rb"

  local file
  file=$(write_fixture "rtg-path-staged.txt" "$(_body_with_rtg "spec/services/session_spec.rb")")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}

@test "Red-then-green: spec-path NOT in staged diff fails with red-then-green-path-not-in-staged" {
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  export GIT_SHIM_DIFF_CACHED_OUTPUT="app/services/session.rb"
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Slice: handler + service + spec"$'\n'"Red-then-green: spec/services/session_spec.rb"

  local file
  file=$(write_fixture "rtg-path-not-staged.txt" "$(_body_with_rtg "spec/services/session_spec.rb")")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"red-then-green-path-not-in-staged"* ]]
}

@test "Red-then-green: garbage value (no extension, not yes/n/a) is rejected" {
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Slice: handler + service + spec"$'\n'"Red-then-green: probably"

  local file
  file=$(write_fixture "rtg-garbage.txt" "$(_body_with_rtg "probably")")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-red-then-green"* ]]
}

@test "Slice: spec-only does not require Red-then-green (Fix 2)" {
  use_trailers "Slice: spec-only"
  local body
  body="$(cat <<'MSG'
Add failing specs for enrollment race-condition handler

Tests written first; the handler implementation follows in the
next commit. These specs define the expected behaviour contract.

Slice: spec-only
MSG
)"
  local file
  file=$(write_fixture "rtg-spec-only.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
}
