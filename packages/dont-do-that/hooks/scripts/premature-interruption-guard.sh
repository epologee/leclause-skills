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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"

INPUT=$(cat)
is_stop_hook_active "$INPUT" && exit 0

LAST_ASSISTANT=$(read_assistant_text "$INPUT" 1000)
[ -z "$LAST_ASSISTANT" ] && exit 0

is_wip_mode "$LAST_ASSISTANT" && exit 0

# Hand off to compliance-reflex-guard when the text contains "?"
if echo "$LAST_ASSISTANT" | tail -c 500 | grep -q '?'; then
  exit 0
fi

# Escape hatch: 🏁 means work is genuinely done
if echo "$LAST_ASSISTANT" | grep -q '🏁'; then
  exit 0
fi

echo '{"decision":"block","reason":"Premature chain-stop? Werk door. Echt klaar? Eindig met 🏁."}'
