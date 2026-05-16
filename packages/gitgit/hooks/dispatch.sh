#!/bin/bash
# Single entry point for all gitgit hooks. Registered against
# PreToolUse (Bash) in hooks.json.
# Routes to the right guard set based on hook_event_name in the stdin JSON.

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/lib/common.sh"

INPUT=$(cat)
EVENT=$(dd_event "$INPUT")

case "$EVENT" in
  PreToolUse)
    TOOL=$(dd_tool_name "$INPUT")
    [ "$TOOL" = "Bash" ] || exit 0

    # The /gitgit:disable-git per-repo lock runs BEFORE the discipline-disable
    # session sentinel. The two answer different questions: disable-git is a
    # safety lock the operator set on this repo, while disable-discipline
    # is a session-wide kill-switch on the commit-discipline guards.
    # Conflating them in a single bypass would silently lift the lock when
    # the operator only wanted to quiet commit-msg validation.
    source "$DIR/guards/git-dash-c.sh"
    source "$DIR/guards/git-config-override.sh"
    source "$DIR/guards/repo-deny.sh"
    guard_git_dash_c "$INPUT"
    guard_git_config_override "$INPUT"
    guard_repo_deny "$INPUT"

    # Session-level kill-switch: when the operator has run
    # /gitgit:disable-discipline, a sentinel file at
    # ~/.claude/var/gitgit-disabled-<session_id> tells the dispatcher to
    # exit 0 for the discipline guards. The disable-git lock above is
    # intentionally evaluated first.
    SESSION_ID=$(dd_session_id "$INPUT")
    if [[ -n "$SESSION_ID" ]] && [[ -f "$HOME/.claude/var/gitgit-disabled-$SESSION_ID" ]]; then
      exit 0
    fi
    if [[ -f "$HOME/.claude/var/gitgit-disabled-global" ]]; then
      exit 0
    fi

    source "$DIR/lib/validate-body.sh"
    source "$DIR/lib/example-synth.sh"
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
