#!/usr/bin/env bats
# amend-rotation-suppression.bats
# A gate-mandated `git commit --amend` of a just-acked commit does not burn
# a fresh rotation slot. Detection signal: HEAD's parent after the amend
# equals the previous HEAD's parent (amend keeps the same parent; a regular
# new commit makes the previous HEAD the parent of the new HEAD).

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  export TMPDIR_TEST
  SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
  DISPATCH="$SCRIPT_DIR/../../hooks/dispatch.sh"

  # Real git repo for the amend semantics (HEAD parent comparison cannot be
  # shimmed cleanly: it requires git rev-parse to resolve arbitrary <sha>^).
  cd "$TMPDIR_TEST" || return 1
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test"
  git config commit.gpgsign false 2>/dev/null || true

  # First commit so HEAD exists.
  echo "seed" > seed.txt
  git add seed.txt
  git -c core.hooksPath=/dev/null commit -q -m "Seed commit"

  # Pre-seed rotation state with pr=3 (rule 4 idx = essentie) so ack-rule4
  # passes the pending-rotation branch deterministically.
  STATE_FILE="$TMPDIR_TEST/commit-rule-state"
  printf 'pv=-1\npr=3\nrp=0\nack_pending_sha=\n' > "$STATE_FILE"
  export GITGIT_COMMIT_RULE_STATE_FILE="$STATE_FILE"
  export GITGIT_SHADOW_LOG="$TMPDIR_TEST/shadow.log"
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

run_pretool() {
  local cmd="$1"
  local json
  json=$(jq -cn --arg c "$cmd" \
    '{hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$c}}')
  run bash "$DISPATCH" <<< "$json"
}

run_posttool() {
  local cmd="$1"
  local json
  json=$(jq -cn --arg c "$cmd" \
    '{hook_event_name:"PostToolUse",tool_name:"Bash",tool_input:{command:$c}}')
  run bash "$DISPATCH" <<< "$json"
}

@test "amend after acked commit keeps rotation slot at the same rp" {
  # Stage a normal commit that the dispatcher will see ack for.
  echo "first" > first.txt
  git add first.txt

  # PreToolUse for the first commit (with valid ack-rule4).
  run_pretool 'git commit -m "Settings panel reaches Windows" # ack-rule4:essentie'
  [ "$status" -eq 0 ] || {
    printf 'PreToolUse for first commit failed: %s\n' "$output" >&2
    return 1
  }

  # Actually land the commit so HEAD advances.
  git -c core.hooksPath=/dev/null commit -q -m "Settings panel reaches Windows"

  # PostToolUse: HEAD moved, no amend signal (parent of HEAD is the seed,
  # parent of ack_pending_sha (which was seed) is empty). So rp advances.
  run_posttool 'git commit -m "Settings panel reaches Windows" # ack-rule4:essentie'

  # Read state after PostToolUse.
  local rp_after_first
  rp_after_first=$(grep '^rp=' "$STATE_FILE" | cut -d= -f2-)

  # Now simulate an amend on the just-landed commit.
  echo "first-updated" >> first.txt
  git add first.txt

  # PreToolUse for the amend.
  run_pretool 'git commit --amend -m "Settings panel reaches Windows on Linux too"'
  # Ack already cleared after first commit's PostToolUse; rotation pr is
  # now whatever PostToolUse advanced to. The amend's PreToolUse may serve
  # a fresh reminder OR pass with the same ack; either way we focus on
  # whether the slot advances after the amend lands.

  # Land the amend.
  git -c core.hooksPath=/dev/null commit --amend -q --no-edit

  # PostToolUse for the amend: should detect amend (same parent) and NOT
  # advance rp.
  # The ack_pending_sha state is whatever PreToolUse for the amend wrote.
  # We assert rp did not advance past rp_after_first.
  run_posttool 'git commit --amend -m "Settings panel reaches Windows on Linux too"'

  local rp_after_amend
  rp_after_amend=$(grep '^rp=' "$STATE_FILE" | cut -d= -f2-)

  # The amend must not have advanced the slot.
  [ "$rp_after_amend" = "$rp_after_first" ] || {
    printf 'rp advanced after amend: rp_after_first=%s rp_after_amend=%s\n' \
      "$rp_after_first" "$rp_after_amend" >&2
    return 1
  }
}

@test "regular new commit after acked commit advances rotation slot" {
  echo "first" > first.txt
  git add first.txt

  run_pretool 'git commit -m "Settings panel reaches Windows" # ack-rule4:essentie'
  [ "$status" -eq 0 ]
  git -c core.hooksPath=/dev/null commit -q -m "Settings panel reaches Windows"

  run_posttool 'git commit -m "Settings panel reaches Windows" # ack-rule4:essentie'
  local rp_after_first
  rp_after_first=$(grep '^rp=' "$STATE_FILE" | cut -d= -f2-)

  # Regular new commit (not amend).
  echo "second" > second.txt
  git add second.txt

  # Pre-seed pr for the new rotation slot the test wants to ack against;
  # the operator would do this by reading the PostToolUse reminder.
  # Compute the next slot index manually.
  local next_pr
  next_pr=$(grep '^pr=' "$STATE_FILE" | cut -d= -f2-)
  # next_pr is currently the slot value (e.g., 3 = essentie). Skip past
  # the ack matching; we only care about whether rp advances after a
  # non-amend lands.

  git -c core.hooksPath=/dev/null commit -q -m "Settings panel reaches Windows again"
  run_posttool 'git commit -m "Settings panel reaches Windows again" # ack-rule4:essentie'

  local rp_after_second
  rp_after_second=$(grep '^rp=' "$STATE_FILE" | cut -d= -f2-)

  # rp must have advanced because the new HEAD's parent is the previous
  # commit's sha, not the seed sha that was the previous parent.
  [ "$rp_after_second" != "$rp_after_first" ] || {
    printf 'rp did not advance after regular new commit: rp_after_first=%s rp_after_second=%s\n' \
      "$rp_after_first" "$rp_after_second" >&2
    return 1
  }
}
