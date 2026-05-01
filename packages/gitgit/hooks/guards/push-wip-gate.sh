#!/bin/bash
# packages/gitgit/hooks/guards/push-wip-gate.sh
# PreToolUse:Bash guard. Blocks `git push` when the push range contains one or
# more commits whose body carries `Slice: wip`.
#
# The shared logic lives in hooks/lib/wip-gate.sh and is also driven by the
# git-native pre-push hook installed by /gitgit:install-hooks. Both paths feed
# the same parser; whichever fires first stops the push.
#
# Parsing simplification.
#   `git push` accepts a great variety of refspecs, options, and remote
#   shorthands. Re-implementing git's own parser here is out of scope. The
#   guard handles the two common shapes:
#     1. Bare `git push` (no remote, no refspec)         -> use @{u}..HEAD.
#     2. `git push <remote>` (no refspec)                -> use @{u}..HEAD.
#     3. `git push <remote> <branch>`                    -> use <remote>/<branch>..<branch>.
#     4. `git push <remote> <local>:<remote-branch>`     -> use <remote>/<remote-branch>..<local>.
#   Anything more exotic (multiple refspecs, --mirror, --all, --tags) falls
#   back to "scan the last 50 commits on HEAD". The fallback is logged to
#   stderr as a warning so the operator knows the gate is in best-effort mode.
#
# Bypass paths.
#   - GITGIT_ALLOW_WIP_PUSH=1 in the bash command (or shell env).
#   - The literal string "# allow-wip-push" anywhere in the bash command.
#   - --force, --force-with-lease do NOT bypass; force-vs-non-force is
#     orthogonal to wip-vs-clean.

guard_push_wip_gate() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ -z "$command" ]] && return 0

  # Match `git push` with possible env-vars before and flags around it.
  # We allow leading "VAR=value " assignments and any leading whitespace.
  local push_re='(^|[[:space:];&|])git[[:space:]]+([A-Za-z0-9_=.-]+[[:space:]]+)*push([[:space:]]|$)'
  if [[ ! "$command" =~ $push_re ]]; then
    return 0
  fi

  # Source the shared lib.
  local DIR
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # shellcheck disable=SC1091
  source "$DIR/lib/wip-gate.sh"

  # ---------------------------------------------------------------------------
  # Determine the range to scan.
  # ---------------------------------------------------------------------------

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)

  # Strip leading env-vars + the `git ... push` prefix to get the push args.
  # Easiest portable shape: chop everything up to and including " push ".
  local args="${command#*push}"
  args="${args# }"

  # Strip trailing shell comments (`# ...`) so the magic-comment bypass is
  # not mis-parsed as positional args. Tokenization below otherwise treats
  # `#` and the comment word as a remote/refspec pair.
  args="${args%%#*}"

  # Drop options to find positional args. Crude tokenization: read whitespace-
  # separated tokens, skip ones starting with "-".
  local -a positional=()
  local tok
  for tok in $args; do
    case "$tok" in
      --) ;;
      -*) ;;
      *) positional+=("$tok") ;;
    esac
  done

  local range=""
  local fallback=0

  case "${#positional[@]}" in
    0)
      # `git push`; use the upstream of HEAD.
      local upstream
      upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
      range=$(wip_gate_parse_range "$upstream" "HEAD")
      ;;
    1)
      # `git push <remote>`. Same as bare push for our purposes.
      local upstream
      upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
      range=$(wip_gate_parse_range "$upstream" "HEAD")
      ;;
    2)
      # `git push <remote> <refspec>`.
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
      ;;
    *)
      # Multiple refspecs or exotic flags. Fall back to scanning the last
      # 50 commits reachable from HEAD; warn so the operator is aware.
      printf '[gitgit/push-wip-gate] note: complex push form, scanning last 50 commits on HEAD as fallback.\n' >&2
      range="HEAD~50..HEAD"
      fallback=1
      # If HEAD~50 does not exist (shallow / new repo), drop to all of HEAD.
      if ! git rev-parse --verify --quiet "HEAD~50" >/dev/null 2>&1; then
        range="HEAD"
      fi
      ;;
  esac

  [[ -z "$range" ]] && return 0

  # ---------------------------------------------------------------------------
  # Find wip commits and decide.
  # ---------------------------------------------------------------------------

  local wip_list
  wip_list=$(wip_gate_find_wip_commits "$range")

  local wip_count=0
  if [[ -n "$wip_list" ]]; then
    wip_count=$(printf '%s\n' "$wip_list" | grep -c .)
  fi

  if wip_gate_should_block "$command" "$wip_count"; then
    local msg
    msg=$(wip_gate_format_message "$wip_list")
    dd_emit_deny "push-wip-gate" "$msg"
    return 0  # unreached; dd_emit_deny exits 2.
  fi

  # If we are here either there were no wip commits, or a bypass was active.
  if [[ "$wip_count" -gt 0 ]]; then
    local mechanism=""
    if [[ "${GITGIT_ALLOW_WIP_PUSH:-0}" = "1" ]]; then
      mechanism="env"
    elif grep -qF '# allow-wip-push' <<< "$command"; then
      mechanism="magic-comment"
    else
      # wip_gate_should_block returned 1 (allow) without a known bypass.
      # This should not happen; log a BUG notice to stderr and skip the log.
      printf '[gitgit/push-wip-gate] BUG: bypass without recognised mechanism\n' >&2
      return 0
    fi
    local sha_csv
    sha_csv=$(printf '%s' "$wip_list" | tr '\n' ',' | sed 's/,$//')
    wip_gate_log_bypass "$sha_csv" "${current_branch:-unknown}" "$mechanism"
  fi

  return 0
}
