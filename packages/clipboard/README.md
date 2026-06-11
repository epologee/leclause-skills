# clipboard (deprecated)

`clipboard` has moved to **`laicluse-agent-tools`** as
`clipboard@laicluse-agent-tools`. The commands are unchanged:
`/clipboard` and `/clipboard slack`.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-tools
claude plugins install clipboard@laicluse-agent-tools
claude plugins uninstall clipboard@leclause
```

One behavioural note for scripts: the successor resolves its
`clipboard-copy` helper via the plugin root instead of a jq lookup, and no
longer ships `bin/clipboard-paths.sh`. Anything that sourced that shim
should invoke the helper directly:

```bash
IP=$(jq -r '.plugins["clipboard@laicluse-agent-tools"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json)
printf 'content' | "$IP/bin/clipboard-copy"
```
