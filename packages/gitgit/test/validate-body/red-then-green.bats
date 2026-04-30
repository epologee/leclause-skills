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
