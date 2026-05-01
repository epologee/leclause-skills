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
    guard_followup "$INPUT"
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
    # false-claims and tool-error run in subshells so that an emit + exit in
    # one of them does not prevent the other from updating its own
    # /tmp/.claude-<guard>-<sid> state on the same fire. Pre-refactor they
    # were separate processes with independent lifecycles; preserve that by
    # subshelling here. First non-empty output wins, in hooks.json order
    # (false-claims before tool-error).
    source "$DIR/guards/false-claims.sh"
    source "$DIR/guards/tool-error.sh"

    FC_OUTPUT=$( guard_false_claims "$INPUT" )
    TE_OUTPUT=$( guard_tool_error "$INPUT" )

    if [ -n "$FC_OUTPUT" ]; then
      echo "$FC_OUTPUT"
      exit 0
    fi
    if [ -n "$TE_OUTPUT" ]; then
      echo "$TE_OUTPUT"
      exit 0
    fi

    # Mutex-respecting guards. If a prior Stop fire already blocked, skip
    # these to avoid re-blocking on the same text across consecutive fires.
    if ! dd_stop_active "$INPUT"; then
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
