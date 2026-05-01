---
name: discipline-status
user-invocable: true
description: >
  Use ONLY when the operator types `/gitgit:discipline-status`. Do not auto-invoke.
  Reports the current enable/disable state of the gitgit guards for this
  session, the sentinel paths, and the active plugin version.
argument-hint: ""
---

# /gitgit:discipline-status

Rapporteer de huidige staat van de gitgit guards voor deze sessie.

## Wat wordt gerapporteerd

- Huidige session_id (als afleidbaar).
- Of de sessie-specifieke sentinel bestaat (`~/.claude/var/gitgit-disabled-<session_id>`).
- Of de globale sentinel bestaat (`~/.claude/var/gitgit-disabled-global`).
- Conclusie: guards ACTIVE of DISABLED.
- Actieve gitgit plugin-versie (gelezen uit `~/.claude/plugins/installed_plugins.json`).
- Aanwezige guard-scripts onder de actieve plugin-install.

## Implementatie

Voer de volgende stappen uit en presenteer de output als een gestructureerd
statusrapport:

```bash
# 1. Session_id
SESSION_ID="${CLAUDE_SESSION_ID:-}"
# Als leeg: zoek het meest recente JSONL-bestand
if [[ -z "$SESSION_ID" ]]; then
  SESSION_ID=$(ls -t "$HOME/.claude/projects/"*/*.jsonl 2>/dev/null | head -1 | xargs basename 2>/dev/null | sed 's/\.jsonl$//' || true)
fi

# 2. Sentinel paden
SESSION_SENTINEL="$HOME/.claude/var/gitgit-disabled-${SESSION_ID}"
GLOBAL_SENTINEL="$HOME/.claude/var/gitgit-disabled-global"

# 3. Check status
[[ -f "$SESSION_SENTINEL" ]] && SESSION_DISABLED=yes || SESSION_DISABLED=no
[[ -f "$GLOBAL_SENTINEL" ]] && GLOBAL_DISABLED=yes || GLOBAL_DISABLED=no

# 4. Plugin versie
PLUGIN_VERSION=$(jq -r '.plugins["gitgit@leclause"][0].version // "unknown"' \
  "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null || echo "unknown")

# 5. Install path voor guard-lijst
INSTALL_PATH=$(jq -r '.plugins["gitgit@leclause"][0].installPath // ""' \
  "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null || true)

# 6. Guard scripts
GUARDS=""
if [[ -d "$INSTALL_PATH/hooks/guards" ]]; then
  GUARDS=$(ls "$INSTALL_PATH/hooks/guards/" 2>/dev/null | tr '\n' ' ')
fi
```

Presenteer het resultaat als:

```
gitgit session status
---------------------
Session ID     : <session_id of "not available">
Session sentinel: <path> [EXISTS / not found]
Global sentinel : <path> [EXISTS / not found]
Guards         : DISABLED / ACTIVE
Plugin version : <version>
Guard scripts  : <lijst van .sh bestanden>
```

Als guards DISABLED zijn, vermeld dan `/gitgit:enable-discipline` om ze te heractiveren.
