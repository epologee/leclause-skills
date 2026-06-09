# gitgit (deprecated)

`gitgit` has moved to **`git-discipline@laicluse-agent-tools`**. This package
is now a tombstone: it ships no skills, no guards, and no commit hooks. Its
only remaining behaviour is a SessionStart notice that points here.

## Migrate

```bash
claude plugins marketplace add epologee/laicluse-agent-tools
claude plugins install git-discipline@laicluse-agent-tools
claude plugins uninstall gitgit@leclause
```

`git-discipline@laicluse-agent-tools` carries the same thirteen skills under
the same names (`commit-all-the-things`, `commit-snipe`, `commit-discipline`,
`rebase-latest-default`, `merge-to-default`, `push-policy`, `install-hooks`,
`run-spec`, `disable-discipline`, `enable-discipline`, `discipline-status`,
`disable-git`, `enable-git`) plus the commit/push hook stack. The slash-command
prefix changes from `/gitgit:` to `/git-discipline:`.

## Why a tombstone instead of a hard delete

Removing a plugin's entry from a marketplace does not uninstall it for users
who already have it: the install stays orphaned in the cache and its hooks keep
running. A tombstone strips the behaviour (killing any conflict with the
successor) while keeping the marketplace entry alive so that the next
`claude plugins update gitgit@leclause` delivers this notice and the exact
uninstall command. See the `how-plugins-work` skill, section "Deprecating and
removing a plugin", for the full pattern.
