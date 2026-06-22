# ground (deprecated)

The `/ground` skill has moved into the **lifeline** plugin at
`lifeline@laicluse-agent-fieldkit`, paired with `/inspire`. The skill is
unchanged.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install lifeline@laicluse-agent-fieldkit
claude plugins uninstall ground@leclause
claude plugins uninstall inspire@leclause
```

Full migration guide:
https://github.com/epologee/laicluse-agent-fieldkit/blob/main/docs/migration.md
