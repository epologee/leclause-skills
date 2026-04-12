#!/bin/bash
# Compliance reflex guard
# Stop hook: blocks Claude from ending responses with unnecessary
# confirmation questions ("Wil je dat ik...?", "Shall I...?") when
# the user gave a clear instruction. Forces continuing the work.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"

INPUT=$(cat)
is_stop_hook_active "$INPUT" && exit 0

LAST_ASSISTANT=$(read_assistant_text "$INPUT" 500 "compliance-reflex")
[ -z "$LAST_ASSISTANT" ] && exit 0

is_wip_mode "$LAST_ASSISTANT" && exit 0

ESCALATION=$(echo "$LAST_ASSISTANT" \
  | grep -cE "^🧭")

if [ "$ESCALATION" -gt 0 ] 2>/dev/null; then
  exit 0
fi

COMPLIANCE_MATCH=$(echo "$LAST_ASSISTANT" \
  | grep -ciE "(wil je dat ik|zal ik|moet ik|shall i|should i|want me to|do you want me to|wilt u dat ik|wat heeft? je voorkeur|what do you prefer|nog (updaten|aanpassen|fixen|doen|starten|draaien)).*\?\s*$")

if [ "$COMPLIANCE_MATCH" -eq 0 ] 2>/dev/null; then
  exit 0
fi

GENUINE_QUESTION=$(echo "$LAST_ASSISTANT" \
  | tail -c 200 \
  | grep -ciE "(bedoel je|do you mean|of (wil je|wilt u)|or (do you|would you)|is dit beter|is this better|welke (van|optie)|which (of|option)|[0-9]+ (issues|bestanden|items|punten|commits|stappen))")

if [ "$GENUINE_QUESTION" -gt 0 ] 2>/dev/null; then
  exit 0
fi

echo '{"decision":"block","reason":"Vraagteken aan het eind. Check: (1) was die vraag voor de user of voor jezelf? (2) stond het antwoord al in de opdracht? (3) mis je context? Reflex → werk door, niet met het kompas omzeilen. Alleen een genuine nieuwe richting begint met 🧭."}'
