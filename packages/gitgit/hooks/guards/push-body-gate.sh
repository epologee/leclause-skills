#!/bin/bash
# allow-comment: PreToolUse:Bash safety net that validates every commit body in the push range against validate_body and denies the push when one or more commits fall short. The companion to PostToolUse commit-body: PostToolUse stays silent during local iteration, push-body-gate is the loud final gate before commits leave the machine.

guard_push_body_gate() {
  local input="$1"

  [[ "${GITGIT_PUSH_BODY_GATE_DISABLED:-0}" = "1" ]] && return 0

  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ -z "$command" ]] && return 0

  dd_is_git_push_command "$command" || return 0

  local DIR
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  source "$DIR/lib/wip-gate.sh"

  local args="${command#*push}"
  args="${args# }"
  args="${args%%#*}"

  local -a positional=()
  local tok stop=0
  for tok in $args; do
    case "$tok" in
      \;|\&|\&\&|\|\||\|) stop=1 ;;
      \>*|\<*) stop=1 ;;
      [0-9]\>*|[0-9]\<*) stop=1 ;;
    esac
    [[ "$stop" -eq 1 ]] && break
    case "$tok" in
      --) ;;
      -*) ;;
      *) positional+=("$tok") ;;
    esac
  done

  local range=""
  if [[ "${#positional[@]}" -eq 2 ]]; then
    local remote="${positional[0]}"
    local refspec="${positional[1]}"
    local local_ref remote_branch
    if [[ "$refspec" == *:* ]]; then
      local_ref="${refspec%%:*}"
      remote_branch="${refspec##*:}"
    else
      local_ref="$refspec"
      remote_branch="$refspec"
    fi
    [[ -z "$local_ref" ]] && local_ref="HEAD"
    local upstream="$remote/$remote_branch"
    range=$(wip_gate_parse_range "$upstream" "$local_ref")
  else
    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    range=$(wip_gate_parse_range "$upstream" "HEAD")
  fi

  [[ -z "$range" ]] && return 0

  local commits
  commits=$(git rev-list "$range" 2>/dev/null || true)
  [[ -z "$commits" ]] && return 0

  local violations=()
  local sha message subject tmpfile output rc shortstat file_count insertion_count
  while IFS= read -r sha; do
    [[ -z "$sha" ]] && continue
    message=$(git log -1 --pretty=format:%B "$sha" 2>/dev/null || true)
    [[ -z "$message" ]] && continue

    subject=$(printf '%s' "$message" | head -1)
    if validate_body_classify_skip "$subject"; then
      continue
    fi

    shortstat=$(GITGIT_VALIDATE_CONTEXT="$sha" _vb_delta_shortstat)
    file_count=$(GITGIT_VALIDATE_CONTEXT="$sha" _vb_delta_files | grep -c . | tr -d ' ')
    insertion_count=0
    if [[ "$shortstat" =~ ([0-9]+)[[:space:]]+insertion ]]; then
      insertion_count="${BASH_REMATCH[1]}"
    fi
    if [[ "$file_count" -le 1 && "$insertion_count" -le 5 ]]; then
      export GITGIT_TRIVIAL_OK=1
    else
      export GITGIT_TRIVIAL_OK=0
    fi

    tmpfile=$(mktemp /tmp/gitgit-push-body-XXXXXX)
    printf '%s' "$message" > "$tmpfile"
    output=$(GITGIT_VALIDATE_CONTEXT="$sha" validate_body "$tmpfile" 2>&1)
    rc=$?
    rm -f "$tmpfile"

    if [[ "$rc" -eq 1 ]]; then
      local short_sha line
      short_sha=$(git rev-parse --short "$sha" 2>/dev/null || printf '%s' "${sha:0:7}")
      line=$(printf '%s' "$output" | head -1)
      violations+=("${short_sha} \"${subject}\": ${line}")
    fi
  done <<< "$commits"

  unset GITGIT_TRIVIAL_OK

  [[ ${#violations[@]} -eq 0 ]] && return 0

  local msg
  msg=$(printf 'Body schema misses in push range:\n')
  local v
  for v in "${violations[@]}"; do
    msg+=$(printf -- '\n  %s' "$v")
  done
  msg+=$(printf '\n\nAmend or interactive-rebase each commit to fix, then retry push. Use /gitgit:disable-discipline if you need to lift the discipline for this session.')

  dd_emit_deny "push-body-gate" "$msg"
}
