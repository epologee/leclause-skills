#!/bin/bash
# packages/gitgit/hooks/guards/commit-subject.sh
# PreToolUse:Bash guard. On every git commit, parse the subject from -m /
# --message / HEREDOC; check rules 1 (activity-word start) and 2 (trigger
# phrasing); otherwise serve a rotating thematic reminder. Blocks until an
# appropriate '# ack-rule<N>' token appears.
#
# State: three lines at $GITGIT_COMMIT_RULE_STATE_FILE (fallback
# $HOME/.claude/var/gitgit-commit-rule-state): pending_violation,
# pending_rotation, rotation_pos. Written atomically via temp-file rename.
#
# One-shot migration: if the old dont-do-that state file exists and the new
# one does not, the old file is copied to the new path on first run.

# Readable short summaries for the single-line block. The long rules with
# full justification stay in the in-source array so the operator can trace
# each code back to its meaning via the README or this file.
_DD_RULES=(
  "Subject beschrijft nieuw gedrag/capability, geen git-activiteit. Activity-word start (Fix/Add/Update/...) verbergt het resultaat."
  "Verwijs niet naar de trigger. 'Address feedback/comments/findings', 'Apply PR comments' beschrijft WAAROM je commit, niet WAT het systeem nu doet."
  "Subject past in 50 (target) / 72 (max) chars. Imperatief, Engels. Geen diff-samenvatting."
  "Body alleen als nodig: 2-4 zinnen prose over het waarom."
  "Geen file listings of class inventaris. De diff toont files al."
  "Geen bullet dumps of meta-narrative ('reviewer vroeg', 'tests faalden')."
  "Logisch onafhankelijke changes = aparte commits. Test + implementation van 1 feature = 1 atomic commit. Formatting drift hoort niet in feature commits."
  "Nooit broken code committen met plan om de volgende commit te fixen."
  "Geen Co-Authored-By van AI tooling tenzij gevraagd."
  "Geen 'Generated with Claude Code' footer."
  "Review de staged diff voor commit. Edit-tool 'updated successfully' is geen bewijs van volledigheid."
  "Commit check = evidence, niet gut feel. Draaide test, raakte endpoint, checkte state."
  "Nooit squash merge. Bewaar commit history zodat reviewers de iteratie zien."
  "Amend is verboden tenzij het onpushed secrets/PII strippen is. Gebruik een nieuwe commit voor follow-up."
)
# Rule 3 (idx 2) is owned by commit-format structurally and stays out of
# the rotation so it does not double up as an ack-bypassable reminder.
_DD_ROTATION_SLOTS=(3 4 5 6 7 8 9 10 11 12 13)

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

_dd_write_state() {
  local file="$1" pv="$2" pr="$3" rp="$4"
  local tmp="${file}.tmp.$$"
  printf '%d\n%d\n%d\n' "$pv" "$pr" "$rp" > "$tmp"
  mv "$tmp" "$file"
}

_dd_commit_deny() {
  local rule_idx="$1" msg="$2" pv="$3" pr="$4" rp="$5" state_file="$6"
  local num=$((rule_idx + 1))
  _dd_write_state "$state_file" "$pv" "$pr" "$rp"
  dd_emit_deny commit-subject "Rule ${num}/14: ${msg}"
}

guard_commit_subject() {
  local input="$1"
  local command
  command=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)
  [[ ! "$command" =~ git[[:space:]]+commit ]] && return 0

  # Subject extraction: delegate to dd_extract_commit_message (shared parser),
  # then take the first line as the subject. This deduplicates the heredoc-first
  # / -m-fallback logic that commit-format.sh and commit-body.sh also use.
  local full_message
  full_message=$(dd_extract_commit_message "$command")
  local subject=""
  if [[ -n "$full_message" ]]; then
    subject=$(printf '%s' "$full_message" | head -1)
  fi

  # Strip HEREDOC body + quoted strings from command for ack-token detection,
  # so an ack buried in the subject itself does not count as approval.
  local cmd_clean
  cmd_clean=$(echo "$command" | awk '
    BEGIN { in_heredoc=0; marker="" }
    in_heredoc {
      trimmed = $0
      sub(/^[[:space:]]+/, "", trimmed)
      if (trimmed == marker) { in_heredoc = 0; marker = "" }
      next
    }
    {
      if (match($0, /<<-?[[:space:]]*['\''"]?[A-Za-z_][A-Za-z0-9_]*['\''"]?/)) {
        tok = substr($0, RSTART, RLENGTH)
        sub(/<<-?[[:space:]]*['\''"]?/, "", tok)
        sub(/['\''"]?$/, "", tok)
        marker = tok
        in_heredoc = 1
      }
      print
    }' || true)
  cmd_clean=$(echo "$cmd_clean" | sed -E $'s/"[^"]*"//g; s/\x27[^\x27]*\x27//g' || true)

  local ack_idx=-1
  if [[ "$cmd_clean" =~ (^|[[:space:]])\#[[:space:]]*ack-rule([0-9]+) ]]; then
    ack_idx=$((${BASH_REMATCH[2]} - 1))
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
  # One-shot migration from the old dont-do-that location.
  local state_file="${GITGIT_COMMIT_RULE_STATE_FILE:-$HOME/.claude/var/gitgit-commit-rule-state}"
  mkdir -p "$(dirname "$state_file")"
  if [[ ! -f "$state_file" ]]; then
    local old_state_file="${CLAUDE_COMMIT_RULE_STATE_FILE:-$HOME/.claude/var/commit-rule-state}"
    if [[ -f "$old_state_file" ]]; then
      cp "$old_state_file" "$state_file"
    fi
  fi

  local pv pr rp
  pv=-1; pr=-1; rp=0
  if [[ -f "$state_file" ]]; then
    pv=$(_dd_read_state_line "$state_file" 1 -1)
    pr=$(_dd_read_state_line "$state_file" 2 -1)
    rp=$(_dd_read_state_line "$state_file" 3 0)
  fi
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

  # Editor-mode commit: no subject parseable, rules 1/2 cannot be checked.
  if [[ -z "$subject" ]]; then
    dd_emit_deny commit-subject "Editor-mode commit verbergt subject. Pass inline: git commit -m \"...\"."
  fi

  # Fresh violation: always deny with rule 1 or 2.
  if [[ "$violation_idx" -ge 0 ]]; then
    local rn=$((violation_idx + 1))
    if [[ "$ack_idx" -eq "$violation_idx" ]]; then
      _dd_commit_deny "$violation_idx" \
        "\"${subject}\" overtreedt nog; rewrite en hou '# ack-rule${rn}' erop." \
        "$violation_idx" "$pr" "$rp" "$state_file"
    else
      _dd_commit_deny "$violation_idx" \
        "\"${subject}\" overtreedt. Rewrite + '# ack-rule${rn}'." \
        "$violation_idx" "$pr" "$rp" "$state_file"
    fi
  fi

  # Pending violation from a previous call: subject must be clean AND ack present.
  if [[ "$pv" -ge 0 ]]; then
    if [[ "$ack_idx" -eq "$pv" ]]; then
      _dd_write_state "$state_file" -1 "$pr" "$rp"
      return 0
    fi
    _dd_commit_deny "$pv" \
      "\"${subject}\" ack ontbreekt. Voeg '# ack-rule$((pv + 1))' toe." \
      "$pv" "$pr" "$rp" "$state_file"
  fi

  # No pending rotation: serve the next slot as a rotating thematic reminder.
  if [[ "$pr" -lt 0 ]]; then
    local selected="${_DD_ROTATION_SLOTS[$rp]}"
    _dd_commit_deny "$selected" \
      "\"${subject}\" rotation reminder. Voeg '# ack-rule$((selected + 1))' toe." \
      -1 "$selected" "$rp" "$state_file"
  fi

  # Pending rotation: ack must match exactly.
  if [[ "$ack_idx" -eq "$pr" ]]; then
    local new_rp=$(( (rp + 1) % ${#_DD_ROTATION_SLOTS[@]} ))
    _dd_write_state "$state_file" -1 -1 "$new_rp"
    return 0
  fi
  _dd_commit_deny "$pr" \
    "\"${subject}\" ack ontbreekt. Voeg '# ack-rule$((pr + 1))' toe." \
    -1 "$pr" "$rp" "$state_file"
}
