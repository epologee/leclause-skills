# Sourced helper. POSIX-sh; no shebang because the file is never executed directly.
#
# Usage in a skill's shell block:
#
#   . "$(jq -r '.plugins["clipboard@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)/bin/clipboard-paths.sh"
#   CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
#
# The sourcing line still uses jq against installed_plugins.json; only the
# validation and the human-readable errors are de-duplicated here.

resolve_clipboard_copy() {
  local ip cmd
  ip=$(jq -r '.plugins["clipboard@leclause"][0].installPath // empty' "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null)
  if [ -z "$ip" ]; then
    echo "clipboard-paths: 'clipboard@leclause' is not installed. Run: claude plugins install clipboard@leclause" >&2
    return 1
  fi
  cmd="$ip/bin/clipboard-copy"
  if [ ! -x "$cmd" ]; then
    echo "clipboard-paths: $cmd not found or not executable. Run: claude plugins update clipboard@leclause" >&2
    return 2
  fi
  printf '%s' "$cmd"
}
