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

## Augment the local session, do not override it

Every plugin and skill in this marketplace lands inside a Claude Code session that already has its own context: a host OS, a project language and toolchain, a user-level CLAUDE.md, other skills from other marketplaces, and an operator whose preferences have crystallised over many sessions. The marketplace adds a layer underneath that context, not a layer on top of it. A skill carries the outcome and the discipline; the local session does the thinking about how that outcome is reached.

The split is WHAT versus HOW. A skill owns the outcome and the gate: the Visual trailer must be present on UI commits, the rover drives autonomously to the destination, `/duh` converts a near-reflex question into the action itself. The local session owns the route: which tool produces the screenshot, which language the rover programs in, which command the converted action turns into. A skill that declares the route ("use tool X, run command Y") replaces the local session's thinking with a recipe. A skill that names the outcome and at most nudges toward a category invites the local session to read its own context and pick.

The active failure mode is a list of dos and don'ts that looks helpful and quietly turns the local Claude off. The moment a skill spells out "use these six tools", the local session stops searching its own environment and reaches for the menu; the menu becomes the ceiling on what gets considered. A principle-shaped nudge ("there are many ways to do X; the route that already works in your environment is the right one") leaves the search open and keeps the local session doing what it is good at: reading its specific context and judging. Thinking is what the marketplace stimulates; recipes are what it avoids.

Every change to a skill or hook in this marketplace gets walked through the same lens: what is the underlying outcome we want, and how do we nudge the invoker toward it without becoming declarative? If the change reads like a recipe, rewrite it as a principle plus the smallest necessary orientation. If the change names a specific tool, ask whether the tool name is load-bearing or whether an equivalent in the operator's setup would do the same job. The marketplace stays useful when its skills name destinations and trust the local session to find its own road.

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
