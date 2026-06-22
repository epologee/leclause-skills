# clipboard (deprecated)

`clipboard` has moved to **`laicluse-agent-fieldkit`** as
`clipboard@laicluse-agent-fieldkit`. The commands are unchanged:
`/clipboard` and `/clipboard slack`.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install clipboard@laicluse-agent-fieldkit
claude plugins uninstall clipboard@leclause
```

One behavioural note for scripts: the successor resolves its
`clipboard-copy` helper via the plugin root instead of a jq lookup, and no
longer ships `bin/clipboard-paths.sh`. The shim's single export,
`resolve_clipboard_copy`, returned the helper's path; compute that path
directly wherever you stored the function's result:

```bash
IP=$(jq -r '.plugins["clipboard@laicluse-agent-fieldkit"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json)
CLIPBOARD_COPY="$IP/bin/clipboard-copy"
printf 'content' | "$CLIPBOARD_COPY"
```
