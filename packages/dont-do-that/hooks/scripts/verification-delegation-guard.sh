#!/bin/bash
# Verification delegation guard
# Stop hook: blocks Claude from delegating verification to the user.
# Catches phrases like "zou moeten werken", "refresh de pagina",
# "check of het werkt", "is nu gefixt", all variants of pushing
# verification onto the user instead of verifying yourself.
#
# Escape hatch: "Geverifieerd:" prefix in the response means Claude
# actually verified before reporting. The hook passes when found.

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Prefer last_assistant_message from Stop hook input (current message text).
# Transcript fallback for older Claude Code versions that don't provide it.
ASSISTANT_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)

if [ -n "$ASSISTANT_MSG" ]; then
  LAST_ASSISTANT=$(echo "$ASSISTANT_MSG" | tail -c 2000)
else
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
  [ -z "$SESSION_ID" ] && exit 0

  TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -1)
  [ -z "$TRANSCRIPT" ] && exit 0

  LINE_FILE="/tmp/.claude-verification-delegation-${SESSION_ID}"
  TOTAL_LINES=$(wc -l < "$TRANSCRIPT" | tr -d ' ')
  LAST_CHECKED=0
  if [ -f "$LINE_FILE" ]; then
    LAST_CHECKED=$(cat "$LINE_FILE")
  else
    LAST_CHECKED=$((TOTAL_LINES > 20 ? TOTAL_LINES - 20 : 0))
  fi
  echo "$TOTAL_LINES" > "$LINE_FILE"

  NEW_LINES=$((TOTAL_LINES - LAST_CHECKED))
  [ "$NEW_LINES" -le 0 ] && exit 0

  LAST_ASSISTANT=$(tail -"$NEW_LINES" "$TRANSCRIPT" \
    | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null \
    | tail -c 2000)
fi

if [ -z "$LAST_ASSISTANT" ]; then
  exit 0
fi

VERIFIED=$(echo "$LAST_ASSISTANT" | grep -ciE "^Geverifieerd:")

if [ "$VERIFIED" -gt 0 ] 2>/dev/null; then
  exit 0
fi

# Filter meta-references: strip pattern words when used in analytical context
# (tables, comparisons, hook descriptions). This prevents the hook from
# triggering on its own pattern words during analysis.
FILTERED=$(echo "$LAST_ASSISTANT" \
  | sed -E 's/verification[_-]delegation[_-]guard//gi' \
  | sed -E 's/`[^`]*`//g' \
  | sed -E 's/"[^"]*"//g' \
  | sed -E 's/\|[^|]*\|//g')

# Category B: claims it works without evidence
CLAIM_MATCH=$(echo "$FILTERED" \
  | grep -ciE "(zou (nu )?moeten (werken|slagen|kloppen|lukken)|dit zou moeten|should (now )?(work|be fixed|be working|be resolved)|is nu (gefixt|opgelost|hersteld)|is now (fixed|working|resolved))")

# Category C: asks user to verify
CHECK_MATCH=$(echo "$FILTERED" \
  | grep -ciE "(check of|controleer of|kun je (checken|kijken|testen|verifi)|kan je (checken|kijken|testen|verifi)|kijk of|kijk even|let me know if|can you (check|verify|confirm|test)|werkt het( nu)?\?|klopt (dat|dit)\?|wil je (het )?(testen|checken))")

# Category D: asks user to take action to verify
ACTION_MATCH=$(echo "$FILTERED" \
  | grep -ciE "(refresh de (pagina|browser)|herlaad de (pagina|browser)|probeer (het |de pagina |opnieuw)?(te |eens)?|restart de (server|app)|herstart de (server|app)|try (refreshing|reloading|again|it)|reload the (page|browser))")

TOTAL=$((CLAIM_MATCH + CHECK_MATCH + ACTION_MATCH))

if [ "$TOTAL" -eq 0 ] 2>/dev/null; then
  exit 0
fi

if [ "$CLAIM_MATCH" -gt 0 ] 2>/dev/null; then
  MSG="Onbewezen claim. Verifieer zelf (screenshot, curl, test, grep) en begin met 'Geverifieerd:'."
elif [ "$CHECK_MATCH" -gt 0 ] 2>/dev/null; then
  MSG="Verificatie delegeren aan de user. Doe het zelf en begin met 'Geverifieerd:'."
else
  MSG="User een actie vragen om te verifiëren. Doe het zelf en begin met 'Geverifieerd:'."
fi

echo "{\"decision\":\"block\",\"reason\":\"${MSG}\"}"
