#!/bin/bash
# Stop hook: stop-gap voor premature chain-stops.
# Claude Code's tool chains haperen soms voordat een gedachtegang af is —
# de user moet dan "ga door" of "." typen om de chain weer op gang te krijgen.
# Deze hook prikkelt Claude om te checken: was dit een bewuste afronding,
# of stopte de chain per ongeluk te vroeg? Geen druk om sneller te werken.
#
# Mutex met detect-compliance-reflex.sh: deze hook firet alleen als de
# laatste regel NIET op "?" eindigt; de compliance reflex hook firet
# alleen als die wel op "?" eindigt. Daardoor kan altijd maar één van
# de twee tegelijk blokkeren.
#
# Skips when:
#   - the last line ends with "?" (compliance reflex hook's domain)
#   - 🏁 appears in the last non-empty line of the assistant text (escape hatch)

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

LAST_LINE=$(echo "$LAST_ASSISTANT" | grep -v '^$' | tail -1)

# Skip when the last line ends with "?" — that's the compliance reflex hook's domain
if echo "$LAST_LINE" | grep -qE '\?[[:space:]]*$'; then
  exit 0
fi

# Escape hatch: 🏁 anywhere in the last 200 bytes of the assistant text.
# Permissive on purpose — covers tool_use blocks between text, trailing
# whitespace, invisible characters, or 🏁 in a slightly earlier text block
# from the same turn.
if echo "$LAST_ASSISTANT" | tail -c 200 | grep -q '🏁'; then
  exit 0
fi

echo '{"decision":"block","reason":"Premature chain-stop? Werk door. Echt klaar? Eindig met 🏁."}'
