# self-improvement (deprecated)

`self-improvement` has moved to **`self-improvement@laicluse-agent-fieldkit`**.
This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install self-improvement@laicluse-agent-fieldkit
claude plugins uninstall self-improvement@leclause
```

The successor keeps the same plugin and skill name; the slash command stays
`/self-improvement`.

## Why a tombstone instead of a hard delete

Removing a plugin's entry from a marketplace does not uninstall it for users
who already have it: the install stays orphaned in the cache. A tombstone
keeps the marketplace entry alive so that the next
`claude plugins update self-improvement@leclause` delivers this notice and the
exact uninstall command. See the `how-plugins-work` skill, section
"Deprecating and removing a plugin", for the full pattern.
