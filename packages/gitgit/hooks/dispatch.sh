#!/bin/bash
# allow-comment: Single entry point for gitgit hooks. PreToolUse:Bash carries safety locks (dash-c, config-override, repo-deny), the push-time gates (wip + body), the rotation-reminder layer (commit-subject), and the commit-message nudge layer (commit-format, commit-body, commit-trailers). The nudge layer emits additionalContext via dd_emit_pre_context instead of denying so the commit lands and Claude amends silently.

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/lib/common.sh"
source "$DIR/lib/version-skew.sh"

INPUT=$(cat)
EVENT=$(dd_event "$INPUT")

case "$EVENT" in
  PreToolUse)
    TOOL=$(dd_tool_name "$INPUT")
    [ "$TOOL" = "Bash" ] || exit 0

    dd_gitgit_version_skew "$INPUT"

    dd_cd_to_bash_target "$INPUT"

    source "$DIR/guards/git-dash-c.sh"
    source "$DIR/guards/git-config-override.sh"
    source "$DIR/guards/repo-deny.sh"
    guard_git_dash_c "$INPUT"
    guard_git_config_override "$INPUT"
    guard_repo_deny "$INPUT"

    SESSION_ID=$(dd_session_id "$INPUT")
    if [[ -n "$SESSION_ID" ]] && [[ -f "$HOME/.claude/var/gitgit-disabled-$SESSION_ID" ]]; then
      exit 0
    fi
    if [[ -f "$HOME/.claude/var/gitgit-disabled-global" ]]; then
      exit 0
    fi

    source "$DIR/lib/validate-body.sh"
    source "$DIR/lib/example-synth.sh"
    source "$DIR/guards/git-first-contact.sh"
    guard_git_first_contact "$INPUT"

    source "$DIR/guards/push-wip-gate.sh"
    source "$DIR/guards/push-body-gate.sh"
    guard_push_wip_gate "$INPUT"
    guard_push_body_gate "$INPUT"

    source "$DIR/guards/commit-subject.sh"
    source "$DIR/guards/commit-format.sh"
    source "$DIR/guards/commit-body.sh"
    source "$DIR/guards/commit-trailers.sh"
    guard_commit_subject "$INPUT"
    guard_commit_format "$INPUT"
    guard_commit_body "$INPUT"
    guard_commit_trailers "$INPUT"
    ;;

  PostToolUse)
    TOOL=$(dd_tool_name "$INPUT")
    [ "$TOOL" = "Bash" ] || exit 0

    SESSION_ID=$(dd_session_id "$INPUT")
    if [[ -n "$SESSION_ID" ]] && [[ -f "$HOME/.claude/var/gitgit-disabled-$SESSION_ID" ]]; then
      exit 0
    fi
    if [[ -f "$HOME/.claude/var/gitgit-disabled-global" ]]; then
      exit 0
    fi

    source "$DIR/guards/commit-subject.sh"
    guard_commit_subject_posttool "$INPUT"
    ;;
esac

exit 0
