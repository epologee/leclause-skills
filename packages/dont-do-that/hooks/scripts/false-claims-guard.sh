#!/bin/bash
# False claims guard
# Stop hook: blocks Claude from dismissing failures as pre-existing,
# not-my-fault, or already-known. Forces investigation or fix.
#
# No stop_hook_active mutex: this guard must always run, even when
# another Stop hook already blocked. The LINE_FILE tracking prevents
# redundant scans.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"

INPUT=$(cat)

ASSISTANT_TEXT=$(read_assistant_text "$INPUT" 2000 "false-claims-guard")
[ -z "$ASSISTANT_TEXT" ] && exit 0

is_wip_mode "$ASSISTANT_TEXT" && exit 0

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
