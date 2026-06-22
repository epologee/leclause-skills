# whywhy (deprecated)

`whywhy` has moved to **`laicluse-agent-fieldkit`** as
`whywhy@laicluse-agent-fieldkit`. The skill is unchanged:
`/whywhy [count] <question>`, the configurable why-chain.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install whywhy@laicluse-agent-fieldkit
claude plugins uninstall whywhy@leclause
```

Full migration guide:
https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
