---
name: discipline-status
user-invocable: true
description: >
  Use ONLY when the operator types `/gitgit:discipline-status`. Do not auto-invoke.
  Reports the current enable/disable state of the gitgit guards for this
  session, the sentinel paths, and the active plugin version.
argument-hint: ""
effort: low
---

# /gitgit:discipline-status

Report the current state of the gitgit guards for this session.

## What is reported

- Current session_id (if derivable).
- Whether the session-specific sentinel exists (`~/.claude/var/gitgit-disabled-<session_id>`).
- Whether the global sentinel exists (`~/.claude/var/gitgit-disabled-global`).
- Conclusion: guards ACTIVE or DISABLED.
- Active gitgit plugin version (read from `~/.claude/plugins/installed_plugins.json`).
- Guard scripts present under the active plugin install.

## Implementation

Perform the following steps and present the output as a structured
status report:

```bash
# 1. Session_id
SESSION_ID="${CLAUDE_SESSION_ID:-}"
# If empty: find the most recent JSONL file
if [[ -z "$SESSION_ID" ]]; then
  SESSION_ID=$(ls -t "$HOME/.claude/projects/"*/*.jsonl 2>/dev/null | head -1 | xargs basename 2>/dev/null | sed 's/\.jsonl$//' || true)
fi

# 2. Sentinel paths
SESSION_SENTINEL="$HOME/.claude/var/gitgit-disabled-${SESSION_ID}"
GLOBAL_SENTINEL="$HOME/.claude/var/gitgit-disabled-global"

# 3. Check status
[[ -f "$SESSION_SENTINEL" ]] && SESSION_DISABLED=yes || SESSION_DISABLED=no
[[ -f "$GLOBAL_SENTINEL" ]] && GLOBAL_DISABLED=yes || GLOBAL_DISABLED=no

# 4. Plugin version
PLUGIN_VERSION=$(jq -r '.plugins["gitgit@leclause"][0].version // "unknown"' \
  "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null || echo "unknown")

# 5. Install path for guard list
INSTALL_PATH=$(jq -r '.plugins["gitgit@leclause"][0].installPath // ""' \
  "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null || true)

# 6. Guard scripts
GUARDS=""
if [[ -d "$INSTALL_PATH/hooks/guards" ]]; then
  GUARDS=$(ls "$INSTALL_PATH/hooks/guards/" 2>/dev/null | tr '\n' ' ')
fi
```

Present the result as:

```
gitgit session status
---------------------
Session ID     : <session_id or "not available">
Session sentinel: <path> [EXISTS / not found]
Global sentinel : <path> [EXISTS / not found]
Guards         : DISABLED / ACTIVE
Plugin version : <version>
Guard scripts  : <list of .sh files>
```

If guards are DISABLED, mention `/gitgit:enable-discipline` to re-enable them.
