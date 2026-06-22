# how-plugins-work (deprecated)

`how-plugins-work` has moved to **`how-plugins-work@laicluse-agent-fieldkit`**.
This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install how-plugins-work@laicluse-agent-fieldkit
claude plugins uninstall how-plugins-work@leclause
```

The successor keeps the same plugin and skill names (`how-plugins-work`,
`test-before-push`), so the slash commands stay `/how-plugins-work` and
`/how-plugins-work:test-before-push`. The living document continues there,
extended with Codex/multi-agent coverage.

## Why a tombstone instead of a hard delete

Removing a plugin's entry from a marketplace does not uninstall it for users
who already have it: the install stays orphaned in the cache, and two enabled
copies with identical skill names resolve unpredictably. A tombstone keeps the
marketplace entry alive so that the next
`claude plugins update how-plugins-work@leclause` delivers this notice and the
exact uninstall command. See the successor's `how-plugins-work` skill, section
"Deprecating and removing a plugin", for the full pattern.
