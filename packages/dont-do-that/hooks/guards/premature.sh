#!/bin/bash
# Stop guard. Stop-gap for premature chain-stops. Fires when the last
# assistant message does not end with "?" and has no 🏁 / 🚦 escape with
# a substantive sentence. Mutually exclusive with compliance-reflex by
# condition: compliance handles the "?" case, this handles the rest.

guard_premature() {
  local input="$1"
  local text
  text=$(dd_assistant_text "$input" 1000)

  # Silent chain-break: model produced tool_use/thinking only, no text. If
  # the transcript already shows prior assistant activity, treat as stop.
  if [ -z "$text" ]; then
    local tr
    tr=$(dd_transcript "$input")
    if [ -n "$tr" ] && [ -f "$tr" ]; then
      local has_prior
      has_prior=$(tail -200 "$tr" | jq -r 'select(.type == "assistant") | .type' 2>/dev/null | head -1)
      if [ -n "$has_prior" ]; then
        dd_emit_block premature "Chain stopte zonder tekst. Schrijf wat je deed, de uitkomst, en of je doorgaat of klaar bent."
      fi
    fi
    return 0
  fi

  dd_is_wip "$text" && return 0

  local has_flag=0 has_gate=0 has_question=0
  grep -q '🏁' <<< "$text" && has_flag=1
  grep -q '🚦' <<< "$text" && has_gate=1
  tail -c 500 <<< "$text" | grep -q '?' && has_question=1

  if [ "$has_flag" -eq 1 ] && [ "$has_question" -eq 1 ]; then
    dd_emit_block premature "🏁 + ? tegenstrijdig. Klaar = geen vraag. Kies."
  fi
  if [ "$has_gate" -eq 1 ] && [ "$has_question" -eq 1 ]; then
    dd_emit_block premature "🚦 + ? dubbelvraag. 🚦 is al de vraag. Haal ? weg."
  fi

  # Hand off to compliance when a trailing question is present.
  [ "$has_question" -eq 1 ] && return 0

  if [ "$has_flag" -eq 1 ]; then
    _dd_premature_substance "$text" && return 0
    dd_emit_block premature "🏁 alleen is geen afsluiting. Schrijf een volzin + 🏁."
  fi
  if [ "$has_gate" -eq 1 ]; then
    _dd_premature_substance "$text" && return 0
    dd_emit_block premature "🚦 alleen is geen pauze. Schrijf een volzin waarop je wacht + 🚦. Eenmaal surface is genoeg; daarna 🏁 ook prima."
  fi

  dd_emit_block premature "Werk door, of eindig met 🏁 (klaar, ook met onpushed commits) / 🚦 (wacht op externe go) + volzin."
}

# _dd_premature_substance <text>
# Returns 0 when the text has a real sentence: 40+ non-space non-emoji
# chars AND at least one sentence terminator. Prevents bare "🏁" free passes.
_dd_premature_substance() {
  local stripped
  stripped=$(echo "$1" | LC_ALL=C tr -d '[:space:]' | python3 -c "
import sys, re
text = sys.stdin.read()
text = re.sub(r'[\U0001F300-\U0001FAFF\U00002600-\U000027BF]', '', text)
sys.stdout.write(text)
" 2>/dev/null)
  local chars
  chars=$(printf '%s' "$stripped" | wc -m | tr -d ' ')
  grep -Eq '[.!:]' <<< "$1" || return 1
  [ "$chars" -ge 40 ]
}
