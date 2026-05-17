#!/bin/bash
# allow-comment: guard rationale stays load-bearing for the dispatcher reader
# allow-comment: forces visual verification before media-sends in iteration loops

guard_visual_verify_before_send() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ -z "$command" ]] && return 0

  [[ "$command" =~ graham[[:space:]]+(file|photo|video|album)[[:space:]] ]] || return 0

  if [[ "$command" =~ verified-visually ]]; then
    return 0
  fi

  local path_token
  path_token=$(printf '%s' "$command" \
    | grep -oE 'graham[[:space:]]+(file|photo|video|album)[[:space:]]+[^[:space:]]+' \
    | awk '{print $NF}' \
    | head -1)
  [[ -z "$path_token" ]] && return 0

  case "$path_token" in
    *.mp4|*.mov|*.webm|*.m4v|*.png|*.jpg|*.jpeg|*.gif) : ;;
    *) return 0 ;;
  esac

  local transcript
  transcript=$(dd_transcript "$input")
  [[ -z "$transcript" ]] && return 0
  [[ ! -f "$transcript" ]] && return 0

  local recent_reads
  recent_reads=$(tail -400 "$transcript" 2>/dev/null \
    | grep -c '"name":"Read".*\.\(png\|jpg\|jpeg\|gif\)' \
    || true)

  if [[ "${recent_reads:-0}" -gt 0 ]]; then
    return 0
  fi

  dd_emit_deny visual-verify-before-send \
"About to send media via graham (${path_token}) without any recent Read on a preview PNG/JPG. In iteration-loops the assistant tends to skip visual verification after a render, claim the change landed, and only discover the regression when the operator catches it (10x more expensive than the pause). Run Read on a preview frame first (e.g. ffmpeg -y -ss <t> -i <video> -vframes 1 -vf scale=540:960 out/preview.png, then Read out/preview.png), confirm visually that the intended change is present, then retry the send. If verification has already happened outside the tool transcript (operator opened it in QuickTime, etc.), add '# verified-visually' anywhere in the bash command to bypass this gate."
}
