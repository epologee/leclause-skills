#!/bin/bash
# packages/gitgit/hooks/guards/commit-subject.sh
# PreToolUse:Bash guard. On every git commit, parse the subject from -m /
# --message / HEREDOC; check rules 1 (activity-word start) and 2 (trigger
# phrasing); otherwise serve a rotating thematic reminder. Blocks until an
# appropriate '# ack-rule<N>:<password>' token appears, where the
# password must match the mnemonic for that rule. The mnemonics live in
# hooks/lib/rotation-rules.sh and are documented in the
# /gitgit:commit-discipline skill (section "Rotation reminders").
#
# State file: key=value text (pv, pr, rp, ack_pending_sha) at
# $GITGIT_COMMIT_RULE_STATE_FILE, falling back to
# $HOME/.claude/var/gitgit-commit-rule-state-<8char-hex-of-toplevel>.
# Written atomically via temp-file rename. The reader also accepts the
# two legacy positional formats (three-line and four-line) so existing
# installations migrate seamlessly on first read.
#
# Migration chain: when the per-toplevel file does not exist, copy from
# the global gitgit file ($HOME/.claude/var/gitgit-commit-rule-state)
# if present, otherwise from the dont-do-that legacy file. The global
# source is renamed to *.migrated after the first successful copy so
# subsequent new repos start fresh instead of inheriting stale state.

# Source the password mnemonics; provides DD_RULE_PASSWORD[].
_DD_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DD_HERE/../lib/rotation-rules.sh"

# Rule 3 (idx 2) is owned by commit-format structurally and stays out of
# the rotation so it does not double up as an ack-bypassable reminder.
_DD_ROTATION_SLOTS=(3 4 5 6 7 8 9 10 11 12 13 14)

_dd_read_state_line() {
  local file="$1" line_no="$2" default="$3"
  local v
  v=$(sed -n "${line_no}p" "$file" 2>/dev/null)
  if [[ "$v" =~ ^-?[0-9]+$ ]]; then
    echo "$v"
  else
    echo "$default"
  fi
}

# Loads state into DD_LOADED_* globals. Reads the canonical key=value
# format and degrades gracefully to the two legacy positional formats
# (three-line: pv/pr/rp; four-line: pv/pr/rp/ack_pending_sha). The next
# write converges any legacy file to the key=value format.
_dd_load_state() {
  local file="$1"
  DD_LOADED_PV=-1
  DD_LOADED_PR=-1
  DD_LOADED_RP=0
  DD_LOADED_ACK_SHA=""
  [[ -f "$file" ]] || return 0
  if grep -qE '^[a-z_]+=' "$file" 2>/dev/null; then
    local key val
    while IFS='=' read -r key val; do
      [[ -z "$key" ]] && continue
      case "$key" in
        pv) [[ "$val" =~ ^-?[0-9]+$ ]] && DD_LOADED_PV="$val" ;;
        pr) [[ "$val" =~ ^-?[0-9]+$ ]] && DD_LOADED_PR="$val" ;;
        rp) [[ "$val" =~ ^-?[0-9]+$ ]] && DD_LOADED_RP="$val" ;;
        ack_pending_sha) DD_LOADED_ACK_SHA=$(printf '%s' "$val" | tr -cd '0-9a-f') ;;
        *) : ;; # forward-compat: unknown keys are ignored
      esac
    done < "$file"
  else
    DD_LOADED_PV=$(_dd_read_state_line "$file" 1 -1)
    DD_LOADED_PR=$(_dd_read_state_line "$file" 2 -1)
    DD_LOADED_RP=$(_dd_read_state_line "$file" 3 0)
    DD_LOADED_ACK_SHA=$(sed -n '4p' "$file" 2>/dev/null | tr -cd '0-9a-f')
  fi
}

_dd_write_state() {
  local file="$1" pv="$2" pr="$3" rp="$4" ack_sha="${5:-}"
  local tmp="${file}.tmp.$$"
  printf 'pv=%d\npr=%d\nrp=%d\nack_pending_sha=%s\n' \
    "$pv" "$pr" "$rp" "$ack_sha" > "$tmp"
  mv "$tmp" "$file"
}

# Returns 0 when the parsed ack matches the expected rule and password.
# All inputs are explicit so the caller can be reasoned about without
# tracing into the helper's enclosing scope.
_dd_ack_matches() {
  local target_idx="$1" ack_idx="$2" ack_password="$3" expected="$4"
  [[ "$ack_idx" -ne "$target_idx" ]] && return 1
  [[ -z "$ack_password" ]] && return 1
  [[ "$ack_password" != "$expected" ]] && return 1
  return 0
}

# Writes the new state and then exits the dispatcher with code 2 via
# dd_emit_deny. Never returns; any code following a call to this
# function in the same branch is unreachable.
_dd_deny_and_exit() {
  local rule_idx="$1" msg="$2" pv="$3" pr="$4" rp="$5" state_file="$6" ack_sha="${7:-}"
  local num=$((rule_idx + 1))
  _dd_write_state "$state_file" "$pv" "$pr" "$rp" "$ack_sha"
  dd_emit_deny commit-subject "Rule ${num}/15: ${msg}"
}

guard_commit_subject() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ ! "$command" =~ git[[:space:]]+commit ]] && return 0

  # Direct pointer to the SKILL.md so Claude can Read the file without
  # grep-fishing through the plugin cache. The lookup itself stays
  # required: this only points at the door, the password still lives
  # behind it. When the absolute path cannot be resolved (broken
  # install, layout regression, stale cache), surface the failure
  # loudly via dd_emit_deny instead of silently degrading to the
  # slash-command form, which would re-introduce the grep-fishing
  # this fix exists to prevent.
  local skill_dir skill_path skill_pointer
  skill_dir=$(cd "$_DD_HERE/../../skills/commit-discipline" 2>/dev/null && pwd)
  skill_path="${skill_dir}/SKILL.md"
  if [[ -z "$skill_dir" || ! -f "$skill_path" ]]; then
    dd_emit_deny commit-subject "install appears broken: cannot resolve SKILL.md path. Reinstall gitgit@leclause."
  fi
  skill_pointer="${skill_path}, section 'Rotation reminders'"

  # Subject extraction: delegate to dd_extract_commit_message (shared parser),
  # then take the first line as the subject. This deduplicates the heredoc-first
  # / -m-fallback logic that commit-format.sh and commit-body.sh also use.
  local full_message
  full_message=$(dd_extract_commit_message "$command")
  local subject=""
  if [[ -n "$full_message" ]]; then
    subject=$(printf '%s' "$full_message" | head -1)
  fi

  # Strip heredoc body + quoted strings from the command for ack-token
  # detection, so an ack buried in the message itself does not count as
  # approval. dd_strip_commit_message lives in common.sh; it shares the
  # heredoc grammar with dd_extract_commit_message so the two parsers
  # cannot drift.
  local cmd_clean
  cmd_clean=$(dd_strip_commit_message "$command")

  # Optional :<password> suffix. Bare `# ack-rule<N>` is still recognised as
  # "user tried to ack" (drives the "still violates" branch when their subject
  # is still violating); only the suffixed form actually clears state.
  local ack_idx=-1
  local ack_password=""
  if [[ "$cmd_clean" =~ (^|[[:space:]])\#[[:space:]]*ack-rule([0-9]+)(:([a-z]+))? ]]; then
    ack_idx=$((${BASH_REMATCH[2]} - 1))
    ack_password="${BASH_REMATCH[4]}"
  fi

  # Rule 1 (idx 0) / Rule 2 (idx 1) violation detection on the subject.
  local activity_re='^(Fix|Improve|Update|Change|Refactor|Add|Extract|Move|Remove|Rename|Drop|Create|Clear)[[:space:]]'
  local trigger_re='^(Address|Apply)[[:space:]]+.*(review|feedback|findings|comments|pride)'
  local violation_idx=-1
  shopt -s nocasematch
  if [[ -n "$subject" ]] && [[ "$subject" =~ $trigger_re ]]; then
    violation_idx=1
  elif [[ -n "$subject" ]] && [[ "$subject" =~ $activity_re ]]; then
    violation_idx=0
  fi
  shopt -u nocasematch

  # State file. GITGIT_COMMIT_RULE_STATE_FILE overrides for tests.
  # When no override is set, the path is namespaced by the worktree's
  # toplevel directory so two repos open in different worktrees do not
  # share rotation state. The hash of the absolute toplevel path
  # collapses worktrees of the same repo onto the same state, which is
  # the natural scope for the discipline. Migrations chain: legacy
  # dont-do-that location → global gitgit path → per-toplevel path.
  local state_file
  if [[ -n "${GITGIT_COMMIT_RULE_STATE_FILE:-}" ]]; then
    state_file="$GITGIT_COMMIT_RULE_STATE_FILE"
  else
    local toplevel toplevel_hash
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$toplevel" ]]; then
      # Prefer shasum (present on macOS and most Linux); md5sum on
      # Linux-minimal images, md5 -q on BSD/macOS without shasum. Each
      # branch yields a hex string so the namespaced path stays in the
      # same alphabet regardless of which tool produced it.
      toplevel_hash=$(printf '%s' "$toplevel" | shasum 2>/dev/null | cut -c1-8)
      [[ -z "$toplevel_hash" ]] && toplevel_hash=$(printf '%s' "$toplevel" | md5sum 2>/dev/null | cut -c1-8)
      [[ -z "$toplevel_hash" ]] && toplevel_hash=$(printf '%s' "$toplevel" | md5 -q 2>/dev/null | cut -c1-8)
      if [[ -n "$toplevel_hash" ]]; then
        state_file="$HOME/.claude/var/gitgit-commit-rule-state-${toplevel_hash}"
      else
        # No hex hasher available; fall back to the global file rather
        # than fabricating a hash. Worktrees of different repos will
        # share state on this host, which is the prior behaviour.
        state_file="$HOME/.claude/var/gitgit-commit-rule-state"
      fi
    else
      state_file="$HOME/.claude/var/gitgit-commit-rule-state"
    fi
  fi
  mkdir -p "$(dirname "$state_file")"
  if [[ ! -f "$state_file" ]]; then
    # Migration chain: prefer the global gitgit file (older repo-shared
    # state) over the legacy dont-do-that file (oldest). Both copies
    # are atomic so two simultaneous sessions cannot race a partial
    # destination.
    local migration_src=""
    local global_state="$HOME/.claude/var/gitgit-commit-rule-state"
    if [[ "$state_file" != "$global_state" && -f "$global_state" ]]; then
      migration_src="$global_state"
    fi
    if [[ -z "$migration_src" ]]; then
      local old_state_file="${CLAUDE_COMMIT_RULE_STATE_FILE:-$HOME/.claude/var/commit-rule-state}"
      [[ -f "$old_state_file" ]] && migration_src="$old_state_file"
    fi
    if [[ -n "$migration_src" ]]; then
      local migr_tmp="${state_file}.tmp.$$"
      if cp "$migration_src" "$migr_tmp" && mv "$migr_tmp" "$state_file"; then
        # Archive the source so subsequent new repos do not all migrate
        # from the same global file and inherit a stale rotation_pos.
        # The first new repo gets the operator's last state; later new
        # repos start fresh.
        mv "$migration_src" "${migration_src}.migrated" 2>/dev/null || true
      fi
    fi
  fi

  _dd_load_state "$state_file"
  local pv="$DD_LOADED_PV" pr="$DD_LOADED_PR" rp="$DD_LOADED_RP"
  local ack_pending_sha="$DD_LOADED_ACK_SHA"
  # Clamp to valid ranges.
  [[ "$pv" -ne -1 && "$pv" -ne 0 && "$pv" -ne 1 ]] && pv=-1
  if [[ "$pr" -ne -1 ]]; then
    local in_rot=0 slot
    for slot in "${_DD_ROTATION_SLOTS[@]}"; do
      [[ "$slot" -eq "$pr" ]] && { in_rot=1; break; }
    done
    [[ "$in_rot" -eq 0 ]] && pr=-1
  fi
  [[ "$rp" -lt 0 || "$rp" -ge "${#_DD_ROTATION_SLOTS[@]}" ]] && rp=0

  # Resolve any pending ack from a previous PreToolUse pass: if HEAD has
  # advanced since the ack was matched, the commit actually landed and the
  # rotation slot is consumed. If HEAD is unchanged, the commit failed at
  # commit-msg, pre-commit, or never ran; the slot stays so the operator
  # acks the same rule again on the next attempt. Either way, clear the
  # pending sha so this resolution only runs once per ack.
  if [[ -n "$ack_pending_sha" ]]; then
    local current_sha
    current_sha=$(git rev-parse HEAD 2>/dev/null | tr -cd '0-9a-f')
    if [[ -z "$current_sha" ]]; then
      # Empty repo (no commits yet) or detached state where rev-parse
      # returned nothing. The pending ack cannot be resolved against a
      # missing HEAD; clear it without advancing and let the next ack
      # resolve once the repo has commits. Treating empty as "no
      # advance" is the safe choice; the alternative would burn the
      # rotation slot on a state we cannot prove succeeded.
      :
    elif [[ "$current_sha" != "$ack_pending_sha" ]]; then
      rp=$(( (rp + 1) % ${#_DD_ROTATION_SLOTS[@]} ))
    fi
    ack_pending_sha=""
    _dd_write_state "$state_file" "$pv" "$pr" "$rp" ""
  fi

  # Editor-mode commit: no subject parseable, rules 1/2 cannot be checked.
  if [[ -z "$subject" ]]; then
    dd_emit_deny commit-subject "Editor-mode commit hides the subject. Pass inline: git commit -m \"...\"."
  fi

  # Fresh violation: always deny with rule 1 or 2.
  if [[ "$violation_idx" -ge 0 ]]; then
    local rn=$((violation_idx + 1))
    if [[ "$ack_idx" -eq "$violation_idx" ]]; then
      _dd_deny_and_exit "$violation_idx" \
        "\"${subject}\" still violates. Rewrite + '# ack-rule${rn}:<password>' (lookup: ${skill_pointer})." \
        "$violation_idx" "$pr" "$rp" "$state_file"
    else
      _dd_deny_and_exit "$violation_idx" \
        "\"${subject}\" violates. Rewrite + '# ack-rule${rn}:<password>' (lookup: ${skill_pointer})." \
        "$violation_idx" "$pr" "$rp" "$state_file"
    fi
  fi

  # Pending violation from a previous call: subject must be clean AND ack
  # must carry the right password.
  if [[ "$pv" -ge 0 ]]; then
    if _dd_ack_matches "$pv" "$ack_idx" "$ack_password" "${DD_RULE_PASSWORD[$pv]}"; then
      _dd_write_state "$state_file" -1 "$pr" "$rp"
      return 0
    fi
    _dd_deny_and_exit "$pv" \
      "\"${subject}\" password missing or wrong. Paste '# ack-rule$((pv + 1)):<password>' (lookup: ${skill_pointer})." \
      "$pv" "$pr" "$rp" "$state_file"
  fi

  # No pending rotation: serve the next slot as a rotating thematic reminder.
  if [[ "$pr" -lt 0 ]]; then
    local selected="${_DD_ROTATION_SLOTS[$rp]}"
    _dd_deny_and_exit "$selected" \
      "reminder. Paste '# ack-rule$((selected + 1)):<password>' (lookup: ${skill_pointer})." \
      -1 "$selected" "$rp" "$state_file"
  fi

  # Pending rotation: ack must match exactly with the right password.
  # Rotation only advances on confirmed commit success, not on PreToolUse
  # pass: record the current HEAD sha so the next dispatcher entry can
  # detect whether the commit actually landed (HEAD moved) or failed at
  # commit-msg / pre-commit (HEAD unchanged).
  if _dd_ack_matches "$pr" "$ack_idx" "$ack_password" "${DD_RULE_PASSWORD[$pr]}"; then
    local head_sha
    head_sha=$(git rev-parse HEAD 2>/dev/null | tr -cd '0-9a-f')
    # allow-comment: workaround for empty-repo Catch-22 (first commit on `git init`)
    [[ -z "$head_sha" ]] && head_sha="0"
    _dd_write_state "$state_file" -1 -1 "$rp" "$head_sha"
    return 0
  fi
  _dd_deny_and_exit "$pr" \
    "password missing or wrong. Paste '# ack-rule$((pr + 1)):<password>' (lookup: ${skill_pointer})." \
    -1 "$pr" "$rp" "$state_file"
}
