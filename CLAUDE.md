@README.md

# Instructions for Claude Code

## Language

This entire repository is in English: source code, comments, commit
messages, READMEs, SKILL.md bodies, BATS test names, error messages,
CHANGELOG entries, and any new documentation. The marketplace is
consumed by users worldwide and frequently loaded into mixed-language
Claude sessions, so the canonical language must be English even when
the operator and the agent talk to each other in another language. A
handful of Dutch key-phrases survive inside hook diagnostics (operator
notes that the upstream maintainer kept Dutch on purpose); do not
translate those, but never introduce new ones. When in doubt, write
English.

## Authoring a new plugin

Two rules that keep plugins portable across Mac, Linux, and Windows:

1. **No symlinks anywhere in the repo.** Pre-commit and CI reject them. Git for Windows defaults to `core.symlinks=false` and turns symlinks into text files on clone; a symlinked skill silently disappears. Every skill lives in exactly one place: `packages/<plugin>/skills/<skill>/`.

2. **Consumer-facing scripts under `packages/<plugin>/bin/` must use a portable shebang.** Claude Code ships every subdirectory of the plugin source into the install cache, including `bin/`, so the helper script there reaches consumers verbatim. When a file under `packages/<plugin>/bin/` starts with `#!`, only `#!/usr/bin/env node` and `#!/usr/bin/env python3` are accepted; the pre-commit hook rejects anything else and tells you what to port to. Files without a shebang are allowed as sourced helpers (for example `clipboard-paths.sh`, which callers load with `.`). Scripts under `packages/<plugin>/skills/<skill>/` ship the same way; they are not hook-checked today and may use a non-portable interpreter when the skill is deliberately platform-scoped (for example the macOS-only `saysay` scripts). Operator-only scripts under repo-root `bin/` can use any shebang.

## Plugin versioning

Every plugin's version in `packages/<name>/.claude-plugin/plugin.json` follows the format `1.0.{commits}`, where `commits` is the number of commits that touched `packages/<name>/` (historical commits to the retired `skills/<name>/` path still count). Versions bump automatically via the repo's pre-commit hook.

Recovery after rebase or manual edits:

```bash
bin/plugin-versions --check   # Report drift
bin/plugin-versions --write   # Fix drift
```

## Plugin cache cleanup

Claude Code keeps every installed version of a plugin under `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` and never cleans up old ones. Each `claude plugins update` adds a fresh directory.

Prune the stale versions for the leclause marketplace:

```bash
bin/plugin-cache-prune           # Dry run
bin/plugin-cache-prune --write   # Remove stale versions
```

Only the active `installPath` from `~/.claude/plugins/installed_plugins.json` is kept per plugin. Plugins no longer installed are removed entirely.
