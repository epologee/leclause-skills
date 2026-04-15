#!/bin/bash
# PostToolUse hook: blocks em dash (U+2014) and en dash (U+2013) characters
# in persisted output.
# Scope: Edit/Write (files) and Bash (clipboard, pipes). Chat is NOT checked.

INPUT=$(cat)
TOOL=$(jq -r '.tool_name' <<< "$INPUT")

if [ "$TOOL" = "Edit" ]; then
  CONTENT=$(jq -r '.tool_input.new_string // empty' <<< "$INPUT")
  SOURCE=$(jq -r '.tool_input.file_path // "unknown file"' <<< "$INPUT")
elif [ "$TOOL" = "Write" ]; then
  CONTENT=$(jq -r '.tool_input.content // empty' <<< "$INPUT")
  SOURCE=$(jq -r '.tool_input.file_path // "unknown file"' <<< "$INPUT")
elif [ "$TOOL" = "Bash" ]; then
  CONTENT=$(jq -r '.tool_input.command // empty' <<< "$INPUT")
  SOURCE="bash command"
else
  exit 0
fi

[ -z "$CONTENT" ] && exit 0

DASH_CLASS=$(printf '[\xe2\x80\x94\xe2\x80\x93]')

VIOLATIONS=$(awk -v pat="$DASH_CLASS" '
  /^```/ { in_code = !in_code; next }
  in_code { next }
  $0 ~ pat { print NR": "$0 }
' <<< "$CONTENT" | head -3)

if [ -n "$VIOLATIONS" ]; then
  jq -n --arg v "$VIOLATIONS" --arg s "$SOURCE" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("DASH DETECTED in " + $s + ". Em-dashes (\u2014) en en-dashes (\u2013) zijn VERBODEN in bestanden en shell commandos (clipboard/pipes). Herschrijf met komma, punt, of haakjes.\nGevonden:\n" + $v)
    }
  }'
fi
