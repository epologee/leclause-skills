#!/bin/bash
# Verification delegation guard
# Stop hook: blocks Claude from delegating verification to the user.
# Catches phrases like "zou moeten werken", "refresh de pagina",
# "check of het werkt", "is nu gefixt".
#
# Escape hatch: "Geverifieerd:" prefix means Claude actually verified.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"

INPUT=$(cat)
is_stop_hook_active "$INPUT" && exit 0

LAST_ASSISTANT=$(read_assistant_text "$INPUT" 2000 "verification-delegation")
[ -z "$LAST_ASSISTANT" ] && exit 0

is_wip_mode "$LAST_ASSISTANT" && exit 0

VERIFIED=$(echo "$LAST_ASSISTANT" | grep -ciE "^Geverifieerd:")

if [ "$VERIFIED" -gt 0 ] 2>/dev/null; then
  exit 0
fi

FILTERED=$(echo "$LAST_ASSISTANT" \
  | sed -E 's/verification[_-]delegation[_-]guard//gi' \
  | sed -E 's/`[^`]*`//g' \
  | sed -E 's/"[^"]*"//g' \
  | sed -E 's/\|[^|]*\|//g')

CLAIM_MATCH=$(echo "$FILTERED" \
  | grep -ciE "(zou (nu )?moeten (werken|slagen|kloppen|lukken)|dit zou moeten|should (now )?(work|be fixed|be working|be resolved)|is nu (gefixt|opgelost|hersteld)|is now (fixed|working|resolved))")

CHECK_MATCH=$(echo "$FILTERED" \
  | grep -ciE "(check of|controleer of|kun je (checken|kijken|testen|verifi)|kan je (checken|kijken|testen|verifi)|kijk of|kijk even|let me know if|can you (check|verify|confirm|test)|werkt het( nu)?\?|klopt (dat|dit)\?|wil je (het )?(testen|checken))")

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
