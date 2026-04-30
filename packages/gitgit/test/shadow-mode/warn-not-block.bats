#!/usr/bin/env bats
# warn-not-block.bats
# Confirm that the shadow guard emits additionalContext on a violation but
# always exits 0 (never denies), and that the shadow log is written correctly.

load helpers

# ---------------------------------------------------------------------------
# Non-trivial commit without body: warn but allow
# ---------------------------------------------------------------------------

@test "non-trivial commit without body emits additionalContext but exits 0" {
  export GIT_SHIM_ORIGIN_URL="https://github.com/epologee/leclause-skills.git"
  export GIT_SHIM_SHORTSTAT=" 5 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'a.rb\nb.rb\nc.rb\nd.rb\ne.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""

  run_dispatch 'git commit -m "Expose session endpoint" # ack-rule4'

  # Must exit 0: shadow-mode never blocks.
  [ "$status" -eq 0 ]
  # Must carry additionalContext.
  [[ "$output" == *'"additionalContext"'* ]]
  [[ "$output" == *'commit-body-shadow'* ]]
  # Must be a PreToolUse hookSpecificOutput.
  [[ "$output" == *'"hookEventName":"PreToolUse"'* ]]
}

@test "shadow log gets exactly one entry after a violation" {
  export GIT_SHIM_ORIGIN_URL="https://github.com/epologee/leclause-skills.git"
  export GIT_SHIM_SHORTSTAT=" 5 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'a.rb\nb.rb\nc.rb\nd.rb\ne.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT=""
  export GIT_SHIM_HEAD_SHORT="deadbee"
  export GIT_SHIM_HEAD_ABBREV="feature/x"

  local before
  before=$(shadow_log_line_count)

  run_dispatch 'git commit -m "Expose session endpoint" # ack-rule4'

  local after
  after=$(shadow_log_line_count)
  [ "$after" -eq $((before + 1)) ]
}

@test "valid commit (with proper body) emits no shadow context and no log entry" {
  export GIT_SHIM_ORIGIN_URL="https://github.com/epologee/leclause-skills.git"
  # Non-trivial diff so the trivial shortcut does not apply.
  export GIT_SHIM_SHORTSTAT=" 5 files changed, 20 insertions(+)"
  export GIT_SHIM_DIFF_NAMES="$(printf 'a.rb\nb.rb\nc.rb\nd.rb\ne.rb')"
  export GIT_SHIM_INTERPRET_TRAILERS_OUTPUT="$VALID_TRAILERS"
  export GIT_SHIM_LS_TREE_OUTPUT="spec/services/session_spec.rb"

  local before
  before=$(shadow_log_line_count)

  # Build a heredoc command containing the valid body.
  local cmd
  cmd=$(commit_cmd_heredoc \
    "Expose session boundary on transaction events" \
    "$(printf 'When StartTransaction or StopTransaction messages arrive with a\nmeter reading that fails domain validation, we previously rejected\nthe entire event, which masked session starts and stops in analytics.\n\nTests: spec/services/session_spec.rb\nSlice: handler + service + spec\nRed-then-green: yes')")

  # Append ack token so commit-subject guard passes rotation.
  cmd="$cmd # ack-rule4"

  run_dispatch "$cmd"

  [ "$status" -eq 0 ]
  [[ "$output" != *'commit-body-shadow'* ]]
  local after
  after=$(shadow_log_line_count)
  [ "$after" -eq "$before" ]
}
