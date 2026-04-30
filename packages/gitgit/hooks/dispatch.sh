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
    source "$DIR/guards/commit-format.sh"
    source "$DIR/guards/commit-subject.sh"
    guard_commit_format "$INPUT"
    guard_commit_subject "$INPUT"
    # Slice 4 adds commit-body.sh
    # Slice 5 adds commit-trailers.sh
    # Slice 6 adds git-dash-c.sh
    # Slice 7 adds push-wip-gate.sh
    ;;
esac

exit 0
