# testing-philosophy (deprecated)

`testing-philosophy` has moved into the **house-rules** plugin at
`house-rules@laicluse-agent-fieldkit`. The skill is unchanged; it now ships
from `house-rules` alongside `programming-philosophy` and `naming-is-hard`.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install house-rules@laicluse-agent-fieldkit
claude plugins uninstall testing-philosophy@leclause
```

Full migration guide:
https://github.com/epologee/laicluse-agent-fieldkit/blob/main/docs/migration.md
