#!/bin/bash
# Single entry point for all gitgit hooks. Registered against
# PreToolUse (Bash) in hooks.json.
# Routes to the right guard set based on hook_event_name in the stdin JSON.

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/lib/common.sh"

INPUT=$(cat)
EVENT=$(dd_event "$INPUT")

# Session-level kill-switch: when the operator has run /gitgit:disable-discipline, a
# sentinel file at ~/.claude/var/gitgit-disabled-<session_id> tells the
# dispatcher to exit 0 silently without invoking any guard. This lets the
# operator work past a noisy guard for the rest of the session without
# touching the global plugin config or disabling hooks for other sessions.
# /gitgit:enable-discipline removes the sentinel; /gitgit:discipline-status reports the current state.
SESSION_ID=$(dd_session_id "$INPUT")
if [[ -n "$SESSION_ID" ]] && [[ -f "$HOME/.claude/var/gitgit-disabled-$SESSION_ID" ]]; then
  exit 0
fi
# Global fallback: if session_id was not available when /gitgit:disable-discipline ran,
# the skill falls back to a session-agnostic sentinel.
if [[ -f "$HOME/.claude/var/gitgit-disabled-global" ]]; then
  exit 0
fi

case "$EVENT" in
  PreToolUse)
    TOOL=$(dd_tool_name "$INPUT")
    [ "$TOOL" = "Bash" ] || exit 0
    source "$DIR/lib/validate-body.sh"
    source "$DIR/lib/example-synth.sh"
    # Slice 5: git-dash-c.sh runs first. It is a hard block on `git -C ...`
    # and there is no point in parsing the command further once that fires.
    source "$DIR/guards/git-dash-c.sh"
    # Slice 7: push-wip-gate fires on `git push`, alongside git-dash-c. Both
    # are git-command-specific guards that gate the call before any commit-
    # message logic runs.
    source "$DIR/guards/push-wip-gate.sh"
    source "$DIR/guards/commit-format.sh"
    source "$DIR/guards/commit-subject.sh"
    # Slice 4 promotes commit-body to block-mode (universal, all repos)
    source "$DIR/guards/commit-body.sh"
    # Slice 5 adds commit-trailers.sh (anthropic Co-Authored-By gate)
    source "$DIR/guards/commit-trailers.sh"
    guard_git_dash_c "$INPUT"
    guard_push_wip_gate "$INPUT"

    # Message-content guards (commit-format, commit-subject, commit-body) are
    # collected so a deny in one does not short-circuit the others. Each guard
    # runs in a subshell that captures stdout and stderr separately: stdout
    # (additionalContext JSON from dd_emit_pre_context) is always forwarded;
    # stderr from a deny (rc=2) accumulates into DD_DENY_MESSAGES and is joined
    # into one exit-2 message at the end. Any other non-zero rc is a guard
    # crash and aborts the dispatcher with that rc so failures stay visible.
    # git-dash-c, push-wip-gate, and commit-trailers stay fail-fast outside
    # this collector.
    DD_DENY_MESSAGES=()
    _dd_run_collect guard_commit_format "$INPUT"
    _dd_run_collect guard_commit_subject "$INPUT"
    _dd_run_collect guard_commit_body "$INPUT"

    if [ "${#DD_DENY_MESSAGES[@]}" -gt 0 ]; then
      for i in "${!DD_DENY_MESSAGES[@]}"; do
        [ "$i" -gt 0 ] && printf '\n' >&2
        printf '%s\n' "${DD_DENY_MESSAGES[$i]}" >&2
      done
      exit 2
    fi

    guard_commit_trailers "$INPUT"
    ;;
esac

exit 0
