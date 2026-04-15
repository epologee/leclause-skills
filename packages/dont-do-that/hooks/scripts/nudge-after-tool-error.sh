#!/bin/bash
# Nudge after tool error
# Stop hook: detects when Claude stops after a failed tool call without
# attempting to debug or retry. Blocks the stop and instructs Claude to
# analyze the error and continue.
#
# Loop safety:
#   - Max 2 nudges per session (hard cap).
#   - Per-fire line tracking via /tmp/.claude-nudge-error-line-<session>:
#     each fire records CURRENT_LINES; the next invocation only re-scans
#     the portion of the transcript that grew since then.
#   - Does NOT bail on stop_hook_active. After a prior Stop hook block
#     Claude can still produce new tool errors before stopping again, and
#     a blanket bail would silence this hook exactly when we need it.
#
# NOTE: This guard reads structured JSONL data (is_error flags, exit codes),
# not assistant text. It uses the transcript directly instead of
# read_assistant_text, which returns text content only.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"

INPUT=$(cat)

# Intentionally no is_stop_hook_active bail here: after a prior Stop hook
# block, Claude may produce more tool calls that fail, then stop again
# silently. stop_hook_active stays true across that second stop, and a
# blanket bail would silence this hook exactly when it's most needed.
# Loop safety comes from the nudge counter cap plus per-fire line tracking
# below: we only fire on NEW errors added since the last fire.

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -1)
fi
[ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ] && exit 0

NUDGE_FILE="/tmp/.claude-nudge-error-${SESSION_ID}"
LAST_LINE_FILE="/tmp/.claude-nudge-error-line-${SESSION_ID}"

NUDGE_COUNT=0
[ -f "$NUDGE_FILE" ] && NUDGE_COUNT=$(cat "$NUDGE_FILE")
if [ "$NUDGE_COUNT" -ge 2 ] 2>/dev/null; then
  exit 0
fi

CURRENT_LINES=$(wc -l < "$TRANSCRIPT" | tr -d ' ')
LAST_LINE=0
[ -f "$LAST_LINE_FILE" ] && LAST_LINE=$(cat "$LAST_LINE_FILE")

# Bail if nothing new happened since the previous fire. Prevents looping
# on the exact same error state across consecutive Stop hook invocations.
if [ "$CURRENT_LINES" -le "$LAST_LINE" ]; then
  exit 0
fi

# Scan the new portion plus a bit of prior context (min 30 lines) so we
# always see a tool_use/tool_result pair even when only one new line arrived.
NEW_LINES=$((CURRENT_LINES - LAST_LINE))
SCAN_LINES=$((NEW_LINES > 30 ? NEW_LINES : 30))

LAST_SIGNIFICANT=$(tail -"$SCAN_LINES" "$TRANSCRIPT" | awk '
  /"is_error"[[:space:]]*:[[:space:]]*true/    { last = "ERROR" }
  /Exit code [1-9]/                             { last = "ERROR" }
  /"type"[[:space:]]*:[[:space:]]*"tool_use"/   { last = "TOOL_USE" }
  END { print last }
')

if [ "$LAST_SIGNIFICANT" != "ERROR" ]; then
  echo "$CURRENT_LINES" > "$LAST_LINE_FILE"
  exit 0
fi

echo "$((NUDGE_COUNT + 1))" > "$NUDGE_FILE"
echo "$CURRENT_LINES" > "$LAST_LINE_FILE"

echo '{"decision":"block","reason":"Als je laatste tool call mislukte: analyseer de error en probeer opnieuw in plaats van te stoppen."}'
