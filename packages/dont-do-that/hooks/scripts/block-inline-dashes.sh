#!/bin/bash
# PostToolUse hook: blocks em-dash (—) and en-dash (–) in ALL output
# Geen uitzonderingen: niet in bestanden, niet in clipboard, niet in chat

INPUT=$(cat)
TOOL=$(jq -r '.tool_name' <<< "$INPUT")
HOOK_EVENT=$(jq -r '.hook_event_name // "PostToolUse"' <<< "$INPUT")

if [ "$HOOK_EVENT" = "Stop" ]; then
  CONTENT=$(jq -r '.last_assistant_message // empty' <<< "$INPUT")
  SOURCE="chat output"
elif [ "$TOOL" = "Edit" ]; then
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

# Strip code blocks, check remaining text for em/en-dashes
VIOLATIONS=$(awk '
  /^```/ { in_code = !in_code; next }
  in_code { next }
  /[—–]/ { print NR": "$0 }
' <<< "$CONTENT" | head -3)

if [ -n "$VIOLATIONS" ]; then
  jq -n --arg v "$VIOLATIONS" --arg s "$SOURCE" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("DASH DETECTED in " + $s + ". Em-dashes (\u2014) en en-dashes (\u2013) zijn VERBODEN. Altijd. Overal. Herschrijf met komma, punt, of haakjes.\nGevonden:\n" + $v)
    }
  }'
fi
