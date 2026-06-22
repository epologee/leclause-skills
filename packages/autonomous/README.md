# autonomous (deprecated)

`autonomous` has moved to **`laicluse-agent-fieldkit`** and was **split into
two plugins** on the way:

- **`rover@laicluse-agent-fieldkit`** carries the mission framework you most
  likely used: `/autonomous:rover` is now `/rover:rover`, and the same
  rename applies to `prepare`, `decide`, `pride`, `trim`, `verify`,
  `stop`, and `rover-help`.
- **`autonomous@laicluse-agent-fieldkit`** keeps only the stay-alive layer
  (keepalive, cron heartbeat with backoff, wake). The rover pulls it in
  by itself when it detects an interactive session; persistent processes
  run without it.

This package is now a tombstone: it ships no skills. Its only remaining
behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
claude plugins install rover@laicluse-agent-fieldkit
claude plugins install autonomous@laicluse-agent-fieldkit
claude plugins uninstall autonomous@leclause
```

Existing loop files under `.autonomous/` in your projects stay readable;
the successor rover wakes them with the same loop-file format. Muscle
memory is the only breaking change: type `/rover:rover` (or any
`/rover:*` skill) where you typed `/autonomous:*` before, except for the
keepalive layer, which stays under `autonomous` and is not normally
invoked by hand.

## Why a tombstone instead of a hard delete

Removing a plugin's entry from a marketplace does not uninstall it for users
who already have it: the install stays orphaned in the cache. A tombstone
keeps the marketplace entry alive so that the next
`claude plugins update autonomous@leclause` delivers this notice and the
exact uninstall command. See the successor's `how-plugins-work` skill, section
"Deprecating and removing a plugin", for the full pattern.
