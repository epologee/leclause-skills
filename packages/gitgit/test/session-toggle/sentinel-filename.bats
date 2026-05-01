#!/usr/bin/env bats
# packages/gitgit/test/session-toggle/sentinel-filename.bats
#
# Verifies that the sentinel filename embeds the session_id and is therefore
# unique per session: two different session_ids produce two independent
# sentinels that do not interfere with each other.

load helpers

@test "sentinel filename includes the session_id verbatim" {
  local sid="unique-session-deadbeef"
  write_session_sentinel "$sid"

  [[ -f "$HOME/.claude/var/gitgit-disabled-$sid" ]]
}

@test "two session sentinels coexist independently" {
  local sid_a="session-alpha"
  local sid_b="session-beta"
  write_session_sentinel "$sid_a"
  write_session_sentinel "$sid_b"

  [[ -f "$HOME/.claude/var/gitgit-disabled-$sid_a" ]]
  [[ -f "$HOME/.claude/var/gitgit-disabled-$sid_b" ]]
}

@test "sentinel for session A suppresses guards for A but not for B" {
  local sid_a="session-suppress"
  local sid_b="session-active"
  write_session_sentinel "$sid_a"

  # Session A: should exit 0 silently.
  run_dispatch_with_session \
    'git commit -m "bad commit no body" # ack-rule4' \
    "$sid_a"
  [ "$status" -eq 0 ]

  # Session B (no sentinel): non-trivial commit should be blocked.
  export GIT_SHIM_SHORTSTAT=" 3 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/models/foo.rb\napp/models/bar.rb\nspec/models/foo_spec.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""

  run_dispatch_with_session \
    'git commit -m "bare subject no body" # ack-rule4' \
    "$sid_b"
  [ "$status" -eq 2 ]
}

@test "removing session sentinel re-enables guards for that session" {
  local sid="session-toggle-test"
  write_session_sentinel "$sid"

  # Confirm guards are suppressed.
  run_dispatch_with_session \
    'git commit -m "bad commit no body" # ack-rule4' \
    "$sid"
  [ "$status" -eq 0 ]

  # Remove sentinel (simulates /gitgit:enable).
  rm "$HOME/.claude/var/gitgit-disabled-$sid"

  # Now guards should run for a non-trivial commit.
  export GIT_SHIM_SHORTSTAT=" 3 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'app/models/foo.rb\napp/models/bar.rb\nspec/models/foo_spec.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""

  run_dispatch_with_session \
    'git commit -m "bare subject no body" # ack-rule4' \
    "$sid"
  [ "$status" -eq 2 ]
}
