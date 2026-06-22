# rename-suggestion (end of life)

`rename-suggestion` is discontinued. There is no successor; the plugin will
not move to `laicluse-agent-fieldkit`.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Remove

```bash
claude plugins uninstall rename-suggestion@leclause
```

The session-rename idea itself needs no plugin: ask your agent for a short
descriptive session name and it will end with a `/rename <name>` line you can
use directly.
