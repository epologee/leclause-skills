# Migrating off the leclause marketplace

The `leclause` marketplace is retired. Its plugins moved to
`laicluse-agent-fieldkit`. Marketplace aliases are installation identities, so
`@leclause` installs do not migrate themselves.

For each plugin you use, install its successor and remove the leclause one. The
plugin's own SessionStart notice names its successor.

Claude Code:

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install <plugin>@laicluse-agent-fieldkit
claude plugins uninstall <plugin>@leclause
```

Codex:

```bash
codex plugin marketplace add epologee/laicluse-agent-fieldkit
codex plugin add <plugin>@laicluse-agent-fieldkit
```

## inspire and ground merged into lifeline

These two became the skills of one plugin, `lifeline`. The `/inspire` and
`/ground` commands and their trigger phrases are unchanged:

```bash
claude plugins install lifeline@laicluse-agent-fieldkit
claude plugins uninstall inspire@leclause
claude plugins uninstall ground@leclause
```

Per-plugin change detail lives in each plugin's changelog, shown once on update.
