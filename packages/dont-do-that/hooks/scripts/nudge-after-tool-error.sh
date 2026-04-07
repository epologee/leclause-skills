#!/bin/bash
# Nudge after tool error
# Stop hook: detects when Claude stops after a failed tool call without
# attempting to debug or retry. Blocks the stop and instructs Claude to
# analyze the error and continue.
# Max 2 nudges per session to prevent infinite retry loops.

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
if [ -z "$SESSION_ID" ]; then exit 0; fi

TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -1)
if [ -z "$TRANSCRIPT" ]; then exit 0; fi

NUDGE_FILE="/tmp/.claude-nudge-error-${SESSION_ID}"
NUDGE_COUNT=0
if [ -f "$NUDGE_FILE" ]; then
  NUDGE_COUNT=$(cat "$NUDGE_FILE")
fi
if [ "$NUDGE_COUNT" -ge 2 ] 2>/dev/null; then
  exit 0
fi

LAST_SIGNIFICANT=$(tail -30 "$TRANSCRIPT" | awk '
  /"is_error"[[:space:]]*:[[:space:]]*true/    { last = "ERROR" }
  /Exit code [1-9]/                             { last = "ERROR" }
  /"type"[[:space:]]*:[[:space:]]*"tool_use"/   { last = "TOOL_USE" }
  END { print last }
')

if [ "$LAST_SIGNIFICANT" != "ERROR" ]; then
  exit 0
fi

echo "$((NUDGE_COUNT + 1))" > "$NUDGE_FILE"

echo '{"decision":"block","reason":"Als je laatste tool call mislukte: analyseer de error en probeer opnieuw in plaats van te stoppen."}'
