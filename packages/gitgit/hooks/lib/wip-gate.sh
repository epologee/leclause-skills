#!/bin/bash
# packages/gitgit/hooks/lib/wip-gate.sh
#
# Shared library for the slice-7 wip-gate. Sourced by both the PreToolUse:Bash
# guard (hooks/guards/push-wip-gate.sh) and the git-native pre-push hook
# (skills/commit-discipline/git-hooks/pre-push). Single source of truth so the
# two enforcement paths cannot drift.
#
# The gate inspects the commits that are about to be pushed and looks at each
# commit body for a Slice trailer. When Slice equals exactly "wip", the commit
# is a work-in-progress commit and pushing it should be blocked unless the
# operator explicitly opts in.
#
# Public functions:
#   wip_gate_parse_range <upstream-ref> <local-ref>
#       Echoes the rev-list range "<upstream>..<local>". When the upstream
#       does not exist (initial push of a new branch), echoes just "<local>"
#       so git rev-list scans every reachable commit on the new branch.
#   wip_gate_find_wip_commits <range>
#       For each commit in <range>, parses the body via
#       `git interpret-trailers --parse` and emits the SHA on stdout when the
#       Slice trailer value is exactly "wip" (case-insensitive on the key,
#       case-sensitive on the value to match validate-body's behaviour).
#   wip_gate_should_block <bash-command-or-empty> <wip-count>
#       Returns 0 (block) when wip-count > 0 AND no bypass is active.
#       Returns 1 (allow) otherwise.
#       Bypass paths:
#         - GITGIT_ALLOW_WIP_PUSH=1 in the current environment
#         - The literal string "# allow-wip-push" appears anywhere in the
#           bash command (the second argument). The git-native hook passes
#           an empty string and only the env var bypass applies there.
#   wip_gate_format_message <wip-sha-list>
#       Multi-line human-readable message naming each wip commit with its
#       short SHA + subject, plus the bypass instructions.
#   wip_gate_log_bypass <sha-csv> <branch> <mechanism>
#       Appends a single line to ~/.claude/var/gitgit-wip-pushes.log:
#         <ISO>|<sha-csv>|<branch>|<mechanism>
#       The log path can be overridden via $GITGIT_WIP_PUSH_LOG (used by tests).
#
# Functions never exit; callers decide how to surface the verdict.

wip_gate_parse_range() {
  local upstream="$1"
  local local_ref="$2"

  # Initial push: upstream is empty, all-zero SHA, or not resolvable.
  if [[ -z "$upstream" ]] \
     || [[ "$upstream" =~ ^0+$ ]] \
     || ! git rev-parse --verify --quiet "$upstream" >/dev/null 2>&1; then
    printf '%s' "$local_ref"
    return 0
  fi

  printf '%s..%s' "$upstream" "$local_ref"
}

wip_gate_find_wip_commits() {
  local range="$1"
  [[ -z "$range" ]] && return 0

  local commits sha body slice_value
  commits=$(git rev-list "$range" 2>/dev/null || true)
  [[ -z "$commits" ]] && return 0

  while IFS= read -r sha; do
    [[ -z "$sha" ]] && continue
    body=$(git log -1 --pretty=format:%B "$sha" 2>/dev/null || true)
    [[ -z "$body" ]] && continue

    # interpret-trailers --parse emits "Key: value" lines for each trailer.
    slice_value=$(printf '%s\n' "$body" \
      | git interpret-trailers --parse 2>/dev/null \
      | awk -F': ' 'tolower($1) == "slice" { sub(/^[Ss]lice:[[:space:]]*/, "", $0); print; exit }')

    # Trim whitespace.
    slice_value="${slice_value#"${slice_value%%[![:space:]]*}"}"
    slice_value="${slice_value%"${slice_value##*[![:space:]]}"}"

    if [[ "$slice_value" = "wip" ]]; then
      printf '%s\n' "$sha"
    fi
  done <<< "$commits"
}

wip_gate_should_block() {
  local command="${1:-}"
  local wip_count="${2:-0}"

  [[ "$wip_count" -le 0 ]] && return 1

  # Env-var bypass.
  if [[ "${GITGIT_ALLOW_WIP_PUSH:-0}" = "1" ]]; then
    return 1
  fi

  # Magic-comment bypass in the bash command string.
  if [[ -n "$command" ]] && grep -qF '# allow-wip-push' <<< "$command"; then
    return 1
  fi

  return 0
}

wip_gate_format_message() {
  local sha_list="$1"
  local out=""
  local sha short subject

  out+=$'wip commits in push range:\n'
  while IFS= read -r sha; do
    [[ -z "$sha" ]] && continue
    short=$(git rev-parse --short "$sha" 2>/dev/null || printf '%s' "$sha")
    subject=$(git log -1 --pretty=format:%s "$sha" 2>/dev/null || printf '<no subject>')
    out+="  ${short} ${subject}"$'\n'
  done <<< "$sha_list"

  out+=$'\nBypass options:\n'
  out+=$'  GITGIT_ALLOW_WIP_PUSH=1 git push ...   (env-var bypass)\n'
  out+=$'  git push ...   # allow-wip-push        (magic-comment bypass)\n'
  out+=$'\nUse of either bypass is logged to ~/.claude/var/gitgit-wip-pushes.log.\n'

  printf '%s' "$out"
}

wip_gate_log_bypass() {
  local sha_csv="$1"
  local branch="$2"
  local mechanism="$3"

  local log="${GITGIT_WIP_PUSH_LOG:-$HOME/.claude/var/gitgit-wip-pushes.log}"
  local dir
  dir=$(dirname "$log")
  mkdir -p "$dir" 2>/dev/null || true

  local ts_iso
  ts_iso=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  printf '%s|%s|%s|%s\n' "$ts_iso" "$sha_csv" "$branch" "$mechanism" \
    >> "$log" 2>/dev/null || true
}
