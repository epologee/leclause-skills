#!/bin/bash
# Stop hook: stop-gap voor premature chain-stops.
# Claude Code's tool chains haperen soms voordat een gedachtegang af is —
# de user moet dan "ga door" of "." typen om de chain weer op gang te krijgen.
# Deze hook prikkelt Claude om te checken: was dit een bewuste afronding,
# of stopte de chain per ongeluk te vroeg? Geen druk om sneller te werken.
#
# Mutex met detect-compliance-reflex.sh: deze hook firet alleen als er
# GEEN "?" in de recente assistant text staat. Daardoor kan altijd maar
# één van de twee tegelijk blokkeren, ook bij multi-block assistant
# turns waar tool_use blocks tussen text-stukken zitten.
#
# Skips when:
#   - "?" appears anywhere in the last 500 bytes (compliance reflex hook's domain)
#   - 🏁 appears anywhere in the recent assistant text (escape hatch)

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -1)
fi

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

LAST_ASSISTANT=$(tail -50 "$TRANSCRIPT" \
  | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text' 2>/dev/null \
  | tail -c 1000)

if [ -z "$LAST_ASSISTANT" ]; then
  exit 0
fi

# Skip when the recent text contains "?" — that's the compliance reflex hook's
# domain. Checked across the whole recent text (not just the last line) to
# survive multi-block assistant turns where tool_use blocks shift the "?"
# out of the very last text block.
if echo "$LAST_ASSISTANT" | tail -c 500 | grep -q '?'; then
  exit 0
fi

# Escape hatch: 🏁 anywhere in the recent assistant text. False positives on
# a chat about the emoji itself are acceptable; false negatives (hook fires
# while 🏁 is visibly present) are what we want to avoid.
if echo "$LAST_ASSISTANT" | grep -q '🏁'; then
  exit 0
fi

echo '{"decision":"block","reason":"Premature chain-stop? Werk door. Echt klaar? Eindig met 🏁."}'
