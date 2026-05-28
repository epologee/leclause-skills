#!/usr/bin/env bats
# Batched error reporting: every batchable schema check runs against a body
# even when an earlier check failed, and validate_body emits all violations
# on stderr in one block before returning 1. The caller (push-body-gate,
# commit-body PreToolUse, commit-msg native hook) sees the full violation
# list per commit instead of one-per-attempt, which eliminates the amend
# cycle that punished operators for malformed commits drafted in the dark.

load helpers

@test "body with missing Slice AND missing Tests reports BOTH codes in one call" {
  use_trailers "Red-then-green: n/a (test fixture, no spec applies)"$'\n'"Verified: operator-confirmed"
  local body
  body="$(cat <<'MSG'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event.

Red-then-green: n/a (test fixture, no spec applies)
Verified: operator-confirmed
MSG
)"
  local file
  file=$(write_fixture "missing-both.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-slice"* ]]
  [[ "$output" == *"missing-tests"* ]]
}

@test "body with short Slice AND missing Tests AND bad Verified reports ALL THREE codes" {
  use_trailers "Slice: hooks"$'\n'"Red-then-green: n/a (test fixture, no spec applies)"$'\n'"Verified: n/a (something fuzzy)"
  local body
  body="$(cat <<'MSG'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event.

Slice: hooks
Red-then-green: n/a (test fixture, no spec applies)
Verified: n/a (something fuzzy)
MSG
)"
  local file
  file=$(write_fixture "three-violations.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"slice-too-short"* ]]
  [[ "$output" == *"missing-tests"* ]]
  [[ "$output" == *"verified-rationale-vague"* ]]
}

@test "body with bad RTG format AND missing Verified reports BOTH" {
  use_trailers "Tests: spec/services/session_spec.rb"$'\n'"Slice: handler + service + spec"$'\n'"Red-then-green: maybe"
  local body
  body="$(cat <<'MSG'
Expose session boundary on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event.

Tests: spec/services/session_spec.rb
Slice: handler + service + spec
Red-then-green: maybe
MSG
)"
  local file
  file=$(write_fixture "rtg-and-verified.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing-red-then-green"* ]]
  [[ "$output" == *"missing-verified"* ]]
}

@test "valid body still passes silently" {
  use_trailers "$VALID_TRAILERS"
  local file
  file=$(write_fixture "valid.txt" "$VALID_BODY_TEMPLATE")

  run invoke_validator "$file"
  [ "$status" -eq 0 ]
  [[ -z "$output" ]]
}

@test "early-return cases still bail without batched-error emission" {
  # vsd-skip-removed is terminal: no other checks should run.
  local body
  body="$(cat <<'MSG'
Expose session endpoint

# vsd-skip: legacy escape

Tests: spec/services/session_spec.rb
MSG
)"
  local file
  file=$(write_fixture "vsd-skip.txt" "$body")

  run invoke_validator "$file"
  [ "$status" -eq 1 ]
  [[ "$output" == *"vsd-skip-removed"* ]]
  # The terminal early-return means we never reach missing-slice or other
  # downstream checks. Asserting absence pins the early-return contract.
  [[ "$output" != *"missing-slice"* ]]
  [[ "$output" != *"missing-tests"* ]]
}
