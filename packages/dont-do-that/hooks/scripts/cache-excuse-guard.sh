#!/bin/bash
# Cache excuse guard
# Stop hook: blocks Claude from blaming "cache" for issues on localhost.
# On development servers, cache is almost never the real cause.
# Forces investigation of the actual root cause.

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Prefer last_assistant_message from Stop hook input (current message text).
# Transcript fallback for older Claude Code versions that don't provide it.
ASSISTANT_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)

if [ -n "$ASSISTANT_MSG" ]; then
  ASSISTANT_TEXT=$(echo "$ASSISTANT_MSG" | tail -c 2000)
else
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
  [ -z "$SESSION_ID" ] && exit 0

  TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -1)
  [ -z "$TRANSCRIPT" ] && exit 0

  LINE_FILE="/tmp/.claude-cache-guard-${SESSION_ID}"
  TOTAL_LINES=$(wc -l < "$TRANSCRIPT" | tr -d ' ')
  LAST_CHECKED=0
  if [ -f "$LINE_FILE" ]; then
    LAST_CHECKED=$(cat "$LINE_FILE")
  else
    LAST_CHECKED=$((TOTAL_LINES > 30 ? TOTAL_LINES - 30 : 0))
  fi
  echo "$TOTAL_LINES" > "$LINE_FILE"

  NEW_LINES=$((TOTAL_LINES - LAST_CHECKED))
  [ "$NEW_LINES" -le 0 ] && exit 0

  ASSISTANT_TEXT=$(tail -"$NEW_LINES" "$TRANSCRIPT" \
    | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null)
fi

# Match cache used as excuse for something not working
# Includes browser cache, asset cache, Turbo cache, and generic "cache" blame
FOUND=$(echo "$ASSISTANT_TEXT" \
  | grep -ciE "(het probleem is|komt door|ligt aan|veroorzaakt door|schuld van).*(cache|gecachet)|(cache|gecachet).*(stale|verouderd|invalide|probleem|oorzaak)|wacht.*(cache|10 minuten).*invalideer|browser.*(cache|gecachet|oude.*versie)|hard.refresh|Cmd.*Shift.*R|esbuild.*watcher.*(niet|cache)|oude.*(JS|javascript|bundle|assets)")

if [ "$FOUND" -gt 0 ] 2>/dev/null; then
  echo '{"decision":"block","reason":"Als je cache noemde als oorzaak: cache is vrijwel nooit de oorzaak op localhost. Onderzoek de werkelijke root cause."}'
fi
