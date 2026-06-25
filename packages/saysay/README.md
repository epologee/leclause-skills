# saysay (deprecated)

`saysay` has moved to **`laicluse-agent-fieldkit`** as
`saysay@laicluse-agent-fieldkit`. The speech mode is unchanged: `/saysay`
turns it on, `/saysay off` exits.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install saysay@laicluse-agent-fieldkit
claude plugins uninstall saysay@leclause
```

Full migration guide:
https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
