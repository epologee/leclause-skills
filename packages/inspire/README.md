# inspire (deprecated)

The `/inspire` skill has moved into the **lifeline** plugin at
`lifeline@laicluse-agent-fieldkit`, paired with `/ground`. The skill is
unchanged.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install lifeline@laicluse-agent-fieldkit
claude plugins uninstall inspire@leclause
claude plugins uninstall ground@leclause
```

Full migration guide:
https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
