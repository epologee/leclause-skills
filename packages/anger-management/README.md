# anger-management (deprecated)

`anger-management` has moved to **`anger-management@laicluse-agent-fieldkit`**.
This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install anger-management@laicluse-agent-fieldkit
claude plugins uninstall anger-management@leclause
```

The successor keeps the same plugin and skill names, so the slash commands
stay identical (`/fuck`, `/shit`, `/crap`, `/wtf`, `/bullshit`, `/damn`,
`/anger-management`, `/anger-management:repair`). It is also multi-agent:
Codex sessions capture to the same global pile, and the background
investigation falls back to `codex exec` when no `claude` CLI is available.
The friction pile moves to `${LAICLUSE_HOME:-~/.laicluse}/anger-management/`;
captures recorded under the old `~/.claude/var/leclause/` path migrate
automatically on the next capture or repair.

## Why a tombstone instead of a hard delete

Removing a plugin's entry from a marketplace does not uninstall it for users
who already have it: the install stays orphaned in the cache. A tombstone
keeps the marketplace entry alive so that the next
`claude plugins update anger-management@leclause` delivers this notice and the
exact uninstall command. See the successor's `how-plugins-work` skill, section
"Deprecating and removing a plugin", for the full pattern.
