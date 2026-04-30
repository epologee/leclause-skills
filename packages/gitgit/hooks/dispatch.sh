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
    source "$DIR/lib/validate-body.sh"
    source "$DIR/guards/commit-format.sh"
    source "$DIR/guards/commit-subject.sh"
    # Slice 3 adds commit-body shadow-mode guard
    source "$DIR/guards/commit-body.sh"
    guard_commit_format "$INPUT"
    guard_commit_subject "$INPUT"
    guard_commit_body "$INPUT"
    # Slice 4 promotes commit-body to block-mode and adds all repos
    # Slice 5 adds commit-trailers.sh
    # Slice 6 adds git-dash-c.sh
    # Slice 7 adds push-wip-gate.sh
    ;;
esac

exit 0
