#!/bin/bash
# False claims guard
# Stop hook: blocks Claude from dismissing failures as pre-existing,
# not-my-fault, or already-known. Forces investigation or fix.

INPUT=$(cat)

# No stop_hook_active mutex: this guard must always run, even when
# another Stop hook (e.g. block-inline-dashes) already blocked.
# The LAST_CHECKED line tracking prevents redundant scans.

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

  LINE_FILE="/tmp/.claude-false-claims-guard-${SESSION_ID}"
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

# Filter out meta-references to the hook itself before scanning
FILTERED_TEXT=$(echo "$ASSISTANT_TEXT" \
  | sed -E 's/false[_-]claims[_-]guard//gi' \
  | sed -E 's/pre-existing[_-]trap[_-]guard//gi' \
  | sed -E 's/pre-existing-trap//gi' \
  | sed -E 's/`pre-existing`//gi' \
  | sed -E 's/`(known issue|bekende bug|already fail[a-z]*)`//gi')

FOUND=$(echo "$FILTERED_TEXT" \
  | grep -ciE "pre-existing (failure|test|error|bug|issue|problem)|bestond(en)? al|reeds bestaand|al bestaand|niet gerelateerd aan (deze|mijn|onze) wijziging|known (issue|bug|flak)|bekende (bug|fout|issue)|was al (stuk|kapot|broken)|already fail")

if [ "$FOUND" -gt 0 ] 2>/dev/null; then
  echo '{"decision":"block","reason":"Boy Scout Rule: pre-existing is geen excuus. Fix het. Enige uitzondering: als er bewijs is van een parallelle sessie in dezelfde working dir, formuleer dat als parallel werk, niet als pre-existing."}'
fi
