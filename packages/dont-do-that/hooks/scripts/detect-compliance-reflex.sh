#!/bin/bash
# Compliance reflex guard
# Stop hook: blocks Claude from ending responses with unnecessary
# confirmation questions ("Wil je dat ik...?", "Shall I...?") when
# the user gave a clear instruction. Forces continuing the work.

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -1)

if [ -z "$TRANSCRIPT" ]; then
  exit 0
fi

LINE_FILE="/tmp/.claude-compliance-reflex-${SESSION_ID}"
TOTAL_LINES=$(wc -l < "$TRANSCRIPT" | tr -d ' ')
LAST_CHECKED=0
if [ -f "$LINE_FILE" ]; then
  LAST_CHECKED=$(cat "$LINE_FILE")
else
  LAST_CHECKED=$((TOTAL_LINES > 20 ? TOTAL_LINES - 20 : 0))
fi
echo "$TOTAL_LINES" > "$LINE_FILE"

NEW_LINES=$((TOTAL_LINES - LAST_CHECKED))
if [ "$NEW_LINES" -le 0 ]; then
  exit 0
fi

LAST_ASSISTANT=$(tail -"$NEW_LINES" "$TRANSCRIPT" \
  | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null \
  | tail -c 500)

if [ -z "$LAST_ASSISTANT" ]; then
  exit 0
fi

ESCALATION=$(echo "$LAST_ASSISTANT" \
  | grep -ciE "^Follow-up:")

if [ "$ESCALATION" -gt 0 ] 2>/dev/null; then
  exit 0
fi

COMPLIANCE_MATCH=$(echo "$LAST_ASSISTANT" \
  | grep -ciE "(wil je dat ik|zal ik|moet ik|shall i|should i|want me to|do you want me to|wilt u dat ik|nog (updaten|aanpassen|fixen|doen|starten|draaien)).*\?\s*$")

if [ "$COMPLIANCE_MATCH" -eq 0 ] 2>/dev/null; then
  exit 0
fi

GENUINE_QUESTION=$(echo "$LAST_ASSISTANT" \
  | tail -c 200 \
  | grep -ciE "(bedoel je|do you mean|of (wil je|wilt u)|or (do you|would you)|is dit beter|is this better|welke (van|optie)|which (of|option)|[0-9]+ (issues|bestanden|items|punten|commits|stappen))")

if [ "$GENUINE_QUESTION" -gt 0 ] 2>/dev/null; then
  exit 0
fi

echo '{"decision":"block","reason":"Vraagteken aan het eind van je antwoord. Ik (de hook) lees de inhoud niet, jij wel. Even drie dingen checken: (1) was die vraag écht voor de user? (2) stond het antwoord al in het gesprek, expliciet of impliciet in wat de user vroeg? (3) mis je context en moet je de oorspronkelijke opdracht opnieuw lezen? Echte nieuwe vraag? Begin met \"Follow-up:\"."}'
