#!/bin/bash
set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$command" =~ gh[[:space:]]api ]] && [[ "$command" =~ body ]]; then
  body_lower=$(echo "$command" | tr '[:upper:]' '[:lower:]')

  followup_patterns=(
    "follow-up"
    "follow up"
    "wordt opgepakt"
    "opgepakt als"
    "buiten scope"
    "niet in scope"
    "in een volgende pr"
    "latere pr"
    "toekomstige pr"
    "aparte pr"
    "los issue"
  )

  for pattern in "${followup_patterns[@]}"; do
    if [[ "$body_lower" == *"$pattern"* ]]; then
      if [[ "$command" == *"Bewust uitgesteld:"* ]]; then
        exit 0
      fi
      echo "BLOCKED: Follow-up taal ('$pattern') zonder expliciete goedkeuring. Begin met 'Bewust uitgesteld:' als de user dit expliciet heeft besloten. Nieuwe code = altijd fix, nooit uitstellen." >&2
      exit 2
    fi
  done
fi

exit 0
