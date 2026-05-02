#!/bin/bash
# packages/gitgit/hooks/lib/ui-touch.sh
#
# Single-purpose lib: classify the staged diff as UI-touched or not.
# Sourced by validate-body.sh (Visual trailer rule), example-synth.sh
# (synthesised template Visual line), and the git-native prepare-commit-msg
# hook (template Visual line).
#
# Public functions:
#
#   _vb_ui_touched_files
#     Echoes a comma-separated list of staged paths that match the UI-touch
#     heuristic, or empty when no UI is touched. Reads `git diff --cached
#     --name-only` once per call.
#
#   _vb_is_ui_touch
#     Convenience wrapper: returns 0 when at least one path is UI-touched,
#     1 otherwise. Equivalent to `[[ -n "$(_vb_ui_touched_files)" ]]`.
#
# Heuristic detail. UI extensions (definitely UI):
#   .tsx .jsx .vue .svelte .html .htm
#   .css .scss .sass .less
#   .erb .haml .slim
#   .storyboard .xib
#   plus any path under a *.xcassets/ directory.
#
# Swift content-grep (.swift only): the staged blob (`git show :<path>`) is
# inspected for SwiftUI / UIKit / AppKit symbols. The boundary patterns
# (`: View([^A-Za-z0-9_]|$)` etc.) match `: View {`, `: View,`, and the
# dominant `: View<EOL>{` form while excluding longer identifiers like
# `ViewModifier`. When `git show :<path>` returns nothing (file not staged
# as a blob, e.g. partial amend), the Swift file is conservatively NOT
# treated as UI; operators opt in via `Visual: n/a (rationale)` if needed.

# Note: no `set -euo pipefail` here. This file is sourced as a library by
# multiple callers (the validator, example-synth, prepare-commit-msg, BATS
# harnesses). Each caller controls its own errexit/pipefail. The functions
# below handle non-zero returns explicitly via conditionals.

_vb_ui_touched_files() {
  local staged
  staged=$(git diff --cached --name-only 2>/dev/null || true)
  [[ -z "$staged" ]] && return 0

  local f
  local matches=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      *.tsx|*.jsx|*.vue|*.svelte|*.html|*.htm) matches="${matches:+$matches, }$f" ;;
      *.css|*.scss|*.sass|*.less)              matches="${matches:+$matches, }$f" ;;
      *.erb|*.haml|*.slim)                     matches="${matches:+$matches, }$f" ;;
      *.storyboard|*.xib)                      matches="${matches:+$matches, }$f" ;;
      *.xcassets/*)                            matches="${matches:+$matches, }$f" ;;
      *.swift)
        local content=""
        content=$(git show ":$f" 2>/dev/null || true)
        if printf '%s' "$content" \
            | grep -qE '(import SwiftUI|import UIKit|import AppKit|: View([^A-Za-z0-9_]|$)|: UIView([^A-Za-z0-9_]|$)|: NSView([^A-Za-z0-9_]|$)|UIViewController|NSViewController)'; then
          matches="${matches:+$matches, }$f"
        fi
        ;;
    esac
  done <<< "$staged"

  printf '%s' "$matches"
}

_vb_is_ui_touch() {
  [[ -n "$(_vb_ui_touched_files)" ]]
}
