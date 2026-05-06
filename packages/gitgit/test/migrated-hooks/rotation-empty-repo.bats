#!/usr/bin/env bats
# Empty repo / unreadable HEAD handling for the rotation. When
# `git rev-parse HEAD` returns nothing (no commits yet), the guard
# must not silently swallow a pending ack or burn a rotation slot.

load helpers

read_rp() { read_state_field "$1" rp; }
read_pending_sha() { read_state_field "$1" ack_pending_sha; }

@test "ack-match in an empty repo refuses with a guidance deny" {
  local state="$BATS_TEST_TMPDIR/commit-rule-state"
  export GITGIT_COMMIT_RULE_STATE_FILE="$state"
  # Pending rotation = rule 11 (idx 10), pending sha empty.
  printf 'pv=-1\npr=10\nrp=7\nack_pending_sha=\n' > "$state"
  # Force the shim to mimic an empty repo for this run only.
  export GIT_SHIM_HEAD_SHA=""

  run_dispatch "git commit -m 'Capture HEAD sha when ack matches' # ack-rule11:loep"
  [ "$status" -eq 2 ]
  [[ "$output" =~ "cannot read HEAD" ]] || {
    printf 'expected empty-HEAD guidance in output, got: %s\n' "$output" >&2
    return 1
  }

  unset GIT_SHIM_HEAD_SHA
}

@test "resolution with empty HEAD clears pending sha without advancing rp" {
  local state="$BATS_TEST_TMPDIR/commit-rule-state"
  export GITGIT_COMMIT_RULE_STATE_FILE="$state"
  # Previous ack stored a pending sha; current shim returns empty for HEAD.
  printf 'pv=-1\npr=-1\nrp=5\nack_pending_sha=feedfacefeedface\n' > "$state"
  export GIT_SHIM_HEAD_SHA=""

  run_dispatch "git commit -m 'Drop bad reading on transaction events'"
  [ "$status" -eq 2 ]

  # rp must NOT have advanced (no proof the commit landed); pending sha
  # is cleared (single-shot resolution semantics).
  [ "$(read_rp "$state")" = "5" ]
  [ -z "$(read_pending_sha "$state")" ]

  unset GIT_SHIM_HEAD_SHA
}
