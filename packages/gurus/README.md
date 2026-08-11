# gurus (deprecated)

`gurus` has moved to **`gurus@laicluse-agent-fieldkit`**. The four skills keep the same names: `gurus:software`, `gurus:council`, `gurus:writers`, and `gurus:gurus`.

This package is now a tombstone: it ships no skills or subagents. Its only remaining behaviour is a SessionStart notice that points to the successor.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install gurus@laicluse-agent-fieldkit
claude plugins uninstall gurus@leclause
```

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
