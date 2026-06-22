# dont-do-that (deprecated)

`dont-do-that` has moved to **`dont-do-that@laicluse-agent-fieldkit`**. This
package is now a tombstone: it ships no skills, no guards, and no hook
dispatcher. Its only remaining behaviour is a SessionStart notice that points
here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install dont-do-that@laicluse-agent-fieldkit
claude plugins uninstall dont-do-that@leclause
```

The successor keeps the same plugin and skill names (`duh`,
`just-a-question`). In Claude Code it also carries the guardrail hook stack. In
Codex it exposes the two correction skills through the generated adapter
package; Claude-specific hooks do not run there.

## Why a tombstone instead of a hard delete

Removing a plugin's entry from a marketplace does not uninstall it for users
who already have it: the install stays orphaned in the cache and its hooks keep
running. A tombstone strips the behaviour (killing any conflict with the
successor) while keeping the marketplace entry alive so that the next
`claude plugins update dont-do-that@leclause` delivers this notice and the
exact uninstall command. See the successor's `how-plugins-work` skill, section
"Deprecating and removing a plugin", for the full pattern.
