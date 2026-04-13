#!/bin/bash
# Stop hook: stop-gap voor premature chain-stops.
# Claude Code's tool chains haperen soms voordat een gedachtegang af is.
# Deze hook prikkelt Claude om te checken: was dit een bewuste afronding,
# of stopte de chain per ongeluk te vroeg?
#
# Mutex met compliance-reflex-guard: deze hook firet alleen als er
# GEEN "?" in de recente assistant text staat. Daardoor kan altijd maar
# een van de twee tegelijk blokkeren.
#
# Skips when:
#   - "?" appears in the last 500 bytes (compliance-reflex-guard's domain)
#   - 🏁 appears in the recent assistant text (escape hatch)
#   - 🚧 appears in the text (WIP mode)
#
# Blocks the contradiction 🏁 + "?": finish-flag and question are
# mutually exclusive. Either the work is done (no question, no check-in)
# or a real question remains (no flag). This catches the bypass where
# trailing 🏁 would otherwise defeat compliance-reflex-guard's \?\s*$ anchor.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"

INPUT=$(cat)
is_stop_hook_active "$INPUT" && exit 0

LAST_ASSISTANT=$(read_assistant_text "$INPUT" 1000)
[ -z "$LAST_ASSISTANT" ] && exit 0

is_wip_mode "$LAST_ASSISTANT" && exit 0

has_flag=0
has_question=0
echo "$LAST_ASSISTANT" | grep -q '🏁' && has_flag=1
echo "$LAST_ASSISTANT" | tail -c 500 | grep -q '?' && has_question=1

# Contradiction: finish-flag and question cannot coexist.
if [ "$has_flag" -eq 1 ] && [ "$has_question" -eq 1 ]; then
  echo '{"decision":"block","reason":"🏁 en ? samen is tegenstrijdig. Klaar = geen vraag. Vraag = geen 🏁. Kies."}'
  exit 0
fi

# Hand off to compliance-reflex-guard when the text contains "?"
[ "$has_question" -eq 1 ] && exit 0

# Escape hatch: 🏁 means work is genuinely done
[ "$has_flag" -eq 1 ] && exit 0

echo '{"decision":"block","reason":"Premature chain-stop? Werk door. Echt klaar? Eindig met 🏁."}'
