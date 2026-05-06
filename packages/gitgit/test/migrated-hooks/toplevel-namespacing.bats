#!/usr/bin/env bats
# Per-toplevel state-file namespacing. The state file path is hashed by
# `git rev-parse --show-toplevel` so two repos open in different
# worktrees do not share rotation state. The legacy global state file
# (one location for the whole user) migrates to the per-toplevel path
# on first read for the current repo.

load helpers

@test "two different toplevels resolve to two different state files" {
  # Use a fake HOME so the test does not touch the operator's real
  # ~/.claude/var.
  local fake_home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fake_home/.claude/var"
  local saved_home="$HOME"
  export HOME="$fake_home"
  unset GITGIT_COMMIT_RULE_STATE_FILE

  # First repo.
  export GIT_SHIM_TOPLEVEL="$BATS_TEST_TMPDIR/repo-a"
  mkdir -p "$GIT_SHIM_TOPLEVEL"
  run_dispatch "git commit -m 'Drop bad reading on transaction events'"
  [ "$status" -eq 2 ]
  local files_after_a
  files_after_a=$(ls "$fake_home/.claude/var/" | sort)

  # Second repo. The state file from the first must persist; the second
  # repo creates its own.
  export GIT_SHIM_TOPLEVEL="$BATS_TEST_TMPDIR/repo-b"
  mkdir -p "$GIT_SHIM_TOPLEVEL"
  run_dispatch "git commit -m 'Drop bad reading on transaction events'"
  [ "$status" -eq 2 ]
  local files_after_b
  files_after_b=$(ls "$fake_home/.claude/var/" | sort)

  # Two distinct state files now exist, both prefixed with the repo
  # base name; counts of files differ between the two snapshots.
  local count_a count_b
  count_a=$(printf '%s\n' "$files_after_a" | grep -c "^gitgit-commit-rule-state-" || true)
  count_b=$(printf '%s\n' "$files_after_b" | grep -c "^gitgit-commit-rule-state-" || true)
  [ "$count_a" = "1" ]
  [ "$count_b" = "2" ]

  unset GIT_SHIM_TOPLEVEL
  export HOME="$saved_home"
}

@test "global state file migrates to per-toplevel path on first read" {
  local fake_home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fake_home/.claude/var"
  local saved_home="$HOME"
  export HOME="$fake_home"
  unset GITGIT_COMMIT_RULE_STATE_FILE

  # Seed a legacy global state file with a recognizable rotation_pos.
  printf 'pv=-1\npr=10\nrp=7\nack_pending_sha=\n' \
    > "$fake_home/.claude/var/gitgit-commit-rule-state"

  export GIT_SHIM_TOPLEVEL="$BATS_TEST_TMPDIR/some-repo"
  mkdir -p "$GIT_SHIM_TOPLEVEL"
  run_dispatch "git commit -m 'Capture HEAD sha when ack matches' # ack-rule11:loep"
  [ "$status" -eq 0 ] || {
    printf 'expected dispatch to pass after migration, got status %s, output: %s\n' \
      "$status" "$output" >&2
    return 1
  }

  # Per-toplevel file now exists with rp preserved at 7 and the shim
  # HEAD as pending sha (proves the seed migrated and the ack matched).
  local per_top_file
  per_top_file=$(ls "$fake_home/.claude/var/gitgit-commit-rule-state-"* 2>/dev/null | head -1)
  [ -n "$per_top_file" ]
  [ "$(read_state_field "$per_top_file" rp)" = "7" ]
  [ "$(read_state_field "$per_top_file" ack_pending_sha)" = "deadbeef00000000" ]

  unset GIT_SHIM_TOPLEVEL
  export HOME="$saved_home"
}
