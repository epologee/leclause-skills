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
#   - 🏁 appears in the recent assistant text (work-done escape hatch)
#   - 🚦 appears in the recent assistant text (waiting-on-user escape
#     hatch: legitimate approval-gate pause, e.g. waiting for a push go)
#   - 🚧 appears in the text (WIP mode)
#
# Blocks contradictions between escape flags and "?":
#   - 🏁 + "?": work is either done or has an open question, not both.
#   - 🚦 + "?": waiting on user input is itself the question, adding "?"
#     double-asks and re-triggers compliance-reflex-guard logic.
# These rules catch bypass attempts where trailing emoji would otherwise
# defeat compliance-reflex-guard's \?\s*$ anchor.

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
has_gate=0
has_question=0
echo "$LAST_ASSISTANT" | grep -q '🏁' && has_flag=1
echo "$LAST_ASSISTANT" | grep -q '🚦' && has_gate=1
echo "$LAST_ASSISTANT" | tail -c 500 | grep -q '?' && has_question=1

# Contradictions: finish-flag or approval-gate paired with a question.
if [ "$has_flag" -eq 1 ] && [ "$has_question" -eq 1 ]; then
  echo '{"decision":"block","reason":"🏁 en ? samen is tegenstrijdig. Klaar = geen vraag. Vraag = geen 🏁. Kies."}'
  exit 0
fi
if [ "$has_gate" -eq 1 ] && [ "$has_question" -eq 1 ]; then
  echo '{"decision":"block","reason":"🚦 en ? samen dubbelvraagt. 🚦 betekent al: ik wacht op jouw go. Haal de ? weg."}'
  exit 0
fi

# Hand off to compliance-reflex-guard when the text contains "?"
[ "$has_question" -eq 1 ] && exit 0

# Shared substantive-text check: an emoji escape only counts when paired
# with a real sentence. A bare "🏁" / "🚦" is the reflex pattern where
# Claude drops an emoji as a free pass. Require at least one sentence
# terminator (. ! :) and 40+ non-emoji, non-whitespace characters.
check_substance() {
  local text="$1"
  local stripped
  stripped=$(echo "$text" | LC_ALL=C tr -d '[:space:]' | python3 -c "
import sys, re
text = sys.stdin.read()
text = re.sub(r'[\U0001F300-\U0001FAFF\U00002600-\U000027BF]', '', text)
sys.stdout.write(text)
" 2>/dev/null)
  local char_count
  char_count=$(printf '%s' "$stripped" | wc -m | tr -d ' ')
  local has_terminator=0
  echo "$text" | grep -Eq '[.!:]' && has_terminator=1
  [ "$char_count" -ge 40 ] && [ "$has_terminator" -eq 1 ]
}

# Escape hatch: 🏁 means work is genuinely done.
if [ "$has_flag" -eq 1 ]; then
  if check_substance "$LAST_ASSISTANT"; then
    exit 0
  fi
  echo '{"decision":"block","reason":"🏁 alleen is geen afsluiting. Schrijf een volzin die vertelt wat klaar is, en zet dan pas 🏁."}'
  exit 0
fi

# Escape hatch: 🚦 means waiting on user approval (commit, push, merge,
# deploy, or any external-effect gate). Legitimate pause, not a reflex.
if [ "$has_gate" -eq 1 ]; then
  if check_substance "$LAST_ASSISTANT"; then
    exit 0
  fi
  echo '{"decision":"block","reason":"🚦 alleen is geen pauze. Schrijf een volzin die vertelt waarop je wacht (welke actie, welke user input), en zet dan pas 🚦. Herhaal de wacht-melding niet elke turn; eenmaal surface is genoeg, daarna is 🏁 prima ook al wachten de commits nog. De user weet het."}'
  exit 0
fi

echo '{"decision":"block","reason":"Premature chain-stop? Werk door. Klaar met dit turn (ook als er onpushed commits liggen)? Eindig met 🏁 plus een volzin wat klaar is. Geen ander werk over en je wacht echt op een externe go (push, merge, deploy) die je nog niet eerder hebt gemeld? Eindig met 🚦 plus een volzin wat je wacht. Heb je dezelfde wacht-melding deze sessie al gegeven? Niet herhalen, kies 🏁."}'
