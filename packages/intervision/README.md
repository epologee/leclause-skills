# intervision (deprecated)

`intervision` has moved to **`intervision@laicluse-agent-fieldkit`**. This
package is now a tombstone: it ships no skills. Its only remaining behaviour
is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install intervision@laicluse-agent-fieldkit
claude plugins uninstall intervision@leclause
```

The successor keeps the same plugin and skill name, so the slash command stays
`/intervision:second-opinion`. It is also multi-agent: the Claude side hands
work to Codex via `codex exec`, and a Codex side hands work to Claude via
`claude -p`.

## Why a tombstone instead of a hard delete

Removing a plugin's entry from a marketplace does not uninstall it for users
who already have it: the install stays orphaned in the cache. A tombstone
keeps the marketplace entry alive so that the next
`claude plugins update intervision@leclause` delivers this notice and the
exact uninstall command. See the successor's `how-plugins-work` skill, section
"Deprecating and removing a plugin", for the full pattern.
