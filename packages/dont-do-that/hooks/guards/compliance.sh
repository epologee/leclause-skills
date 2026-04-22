#!/bin/bash
# Stop guard. Blocks "Wil je dat ik...?"-style compliance-reflex questions
# when Claude already had a clear instruction to act. Pass with 🧭 prefix
# for a genuine new direction or a pre-emptive forward question.

guard_compliance() {
  local input="$1"
  local text
  text=$(dd_assistant_text "$input" 500 "compliance-reflex")
  [ -z "$text" ] && return 0
  dd_is_wip "$text" && return 0

  grep -qE "^🧭" <<< "$text" && return 0

  grep -qiE "(wil je dat ik|zal ik|moet ik|shall i|should i|want me to|do you want me to|wilt u dat ik|wat heeft? je voorkeur|what do you prefer|nog (updaten|aanpassen|fixen|doen|starten|draaien)).*\?\s*$" <<< "$text" \
    || return 0

  # Genuine-question hatch: words that signal a real disambiguation question.
  tail -c 200 <<< "$text" \
    | grep -qiE "(bedoel je|do you mean|of (wil je|wilt u)|or (do you|would you)|is dit beter|is this better|welke (van|optie)|which (of|option)|[0-9]+ (issues|bestanden|items|punten|commits|stappen))" \
    && return 0

  dd_emit_block compliance "? aan einde. Werk door of start met 🧭 voor een genuine nieuwe richting."
}
