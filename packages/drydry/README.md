# drydry (deprecated)

`drydry` has moved to **`laicluse-agent-fieldkit`** as
`drydry@laicluse-agent-fieldkit`. The orchestrator is unchanged:
`/drydry:drydry`, with quick and audit modes.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install drydry@laicluse-agent-fieldkit
claude plugins uninstall drydry@leclause
```

Full migration guide:
https://github.com/epologee/laicluse-agent-fieldkit/blob/main/docs/migration.md
