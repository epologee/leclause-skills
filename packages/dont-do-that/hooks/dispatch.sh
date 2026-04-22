#!/bin/bash
# Single entry point for all dont-do-that hooks. Registered against
# PreToolUse (Bash), PostToolUse (Edit|Write|Bash), and Stop in hooks.json.
# Routes to the right guard set based on hook_event_name in the stdin JSON.

DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/lib/common.sh"

INPUT=$(cat)
EVENT=$(dd_event "$INPUT")

case "$EVENT" in
  PreToolUse)
    TOOL=$(dd_tool_name "$INPUT")
    [ "$TOOL" = "Bash" ] || exit 0
    source "$DIR/guards/followup.sh"
    source "$DIR/guards/commit-rule.sh"
    guard_followup "$INPUT"
    guard_commit_rule "$INPUT"
    ;;

  PostToolUse)
    TOOL=$(dd_tool_name "$INPUT")
    case "$TOOL" in
      Edit|Write|Bash)
        source "$DIR/guards/dash.sh"
        guard_dash "$INPUT"
        ;;
    esac
    ;;

  Stop)
    # false-claims and tool-error maintain their own line-tracking state
    # and intentionally run even when a previous Stop fire blocked. The
    # other four guards skip on the stop_hook_active mutex to avoid
    # re-blocking on the same text across consecutive fires.
    source "$DIR/guards/false-claims.sh"
    source "$DIR/guards/tool-error.sh"
    guard_false_claims "$INPUT"
    guard_tool_error "$INPUT"

    if ! dd_stop_active "$INPUT"; then
      # Cache first (matches historical hooks.json ordering), then the
      # premature-vs-compliance mutex pair, then verify.
      source "$DIR/guards/cache.sh"
      source "$DIR/guards/premature.sh"
      source "$DIR/guards/verify.sh"
      source "$DIR/guards/compliance.sh"
      guard_cache "$INPUT"
      guard_premature "$INPUT"
      guard_verify "$INPUT"
      guard_compliance "$INPUT"
    fi
    ;;
esac

exit 0
