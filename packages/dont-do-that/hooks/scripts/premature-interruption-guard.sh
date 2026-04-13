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

# Silent chain-break: the model produced only thinking and/or tool_use
# content in its last assistant message, no text. The harness closes the
# turn and this guard used to exit 0, letting it through. If the transcript
# shows any prior assistant activity, treat missing text as a stop signal.
if [ -z "$LAST_ASSISTANT" ]; then
  TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
  if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
    [ -n "$SESSION_ID" ] && TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" -type f 2>/dev/null | head -1)
  fi
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    has_prior_assistant=$(tail -200 "$TRANSCRIPT" | jq -r 'select(.type == "assistant") | .type' 2>/dev/null | head -1)
    if [ -n "$has_prior_assistant" ]; then
      echo '{"decision":"block","reason":"Chain stopte zonder tekst in je laatste bericht. Alleen tool calls of thinking zonder volzin telt als premature stop. Schrijf wat je gedaan hebt, wat de uitkomst was, en of je doorgaat of klaar bent."}'
      exit 0
    fi
  fi
  exit 0
fi

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

# Escape hatch: 🏁 means work is genuinely done, but only when paired
# with a real sentence. A bare "🏁" or "klaar 🏁" is the reflex pattern
# where Claude drops the flag as a free pass after compliance-reflex-guard
# blocked the prior turn. Require substantive text: at least one sentence
# terminator (. ! :) and 40+ non-emoji, non-whitespace characters.
if [ "$has_flag" -eq 1 ]; then
  stripped=$(echo "$LAST_ASSISTANT" | LC_ALL=C tr -d '[:space:]' | python3 -c "
import sys, re
text = sys.stdin.read()
text = re.sub(r'[\U0001F300-\U0001FAFF\U00002600-\U000027BF]', '', text)
sys.stdout.write(text)
" 2>/dev/null)
  char_count=$(printf '%s' "$stripped" | wc -m | tr -d ' ')
  has_terminator=0
  echo "$LAST_ASSISTANT" | grep -Eq '[.!:]' && has_terminator=1
  if [ "$char_count" -ge 40 ] && [ "$has_terminator" -eq 1 ]; then
    exit 0
  fi
  echo '{"decision":"block","reason":"🏁 alleen is geen afsluiting. Schrijf een volzin die vertelt wat klaar is, en zet dan pas 🏁."}'
  exit 0
fi

echo '{"decision":"block","reason":"Premature chain-stop? Werk door. Echt klaar? Eindig met 🏁."}'
