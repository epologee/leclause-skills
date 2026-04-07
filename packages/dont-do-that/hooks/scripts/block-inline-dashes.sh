#!/bin/bash
# PostToolUse hook: warns when em-dash (—) or en-dash (–) appears in non-code text
# Dashes zijn alleen toegestaan in code en als bullet point/lijstitem

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_response.filePath // .tool_input.file_path' <<< "$INPUT")

# Only check text/markdown files
case "$FILE_PATH" in
  *.md|*.txt|*.mdx) ;;
  *) exit 0 ;;
esac

# Get the new content that was just written
TOOL=$(jq -r '.tool_name' <<< "$INPUT")
if [ "$TOOL" = "Edit" ]; then
  CONTENT=$(jq -r '.tool_input.new_string // empty' <<< "$INPUT")
elif [ "$TOOL" = "Write" ]; then
  CONTENT=$(jq -r '.tool_input.content // empty' <<< "$INPUT")
else
  exit 0
fi

[ -z "$CONTENT" ] && exit 0

# Strip code blocks and bullet points, check for em/en-dashes
VIOLATIONS=$(awk '
  /^```/ { in_code = !in_code; next }
  in_code { next }
  /^[[:space:]]*[-*+] / { next }
  /[—–]/ { print NR": "$0 }
' <<< "$CONTENT" | head -3)

if [ -n "$VIOLATIONS" ]; then
  jq -n --arg v "$VIOLATIONS" --arg f "$FILE_PATH" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: ("DASH DETECTED in " + $f + ". Em-dashes (\u2014) en en-dashes (\u2013) zijn verboden in lopende tekst. Herschrijf met komma, punt, of haakjes.\nGevonden:\n" + $v)
    }
  }'
fi
