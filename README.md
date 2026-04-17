# Lecl(a)use Skills

A curated subset of the skills I built while developing applications in Ruby, Swift, Go, JavaScript, Python, Kotlin, and others across various projects. These are the ones I managed to make reusable for colleagues and friends.

I typically prompt in Dutch but write English code, so these skills are a mix of both. The `export-skill` skill can translate if needed.

## Install

Same command on macOS, Linux, and Windows:

```bash
claude plugins marketplace add epologee/leclause-skills
claude plugins install <plugin-name>@leclause
```

The `@leclause` suffix in the second command is the marketplace alias that the first command registers (from `.claude-plugin/marketplace.json`'s `name` field), not a branch ref. Every skill lives at its final location under `packages/<plugin>/skills/<skill>/`, so Windows consumers with the default `core.symlinks=false` get working directories out of the box.

## Skills

| Plugin | Command | Auto | Hooks | Description |
|--------|---------|:----:|:-----:|-------------|
| **autonomous** | `/autonomous:rover` | | | Dispatch a rover at a task. You stay back, the rover works in the field; the distance means it decides autonomously. Ships with eight skills: `rover` (entry), `help` (briefing), `cron` (scheduling + backoff), `decide` (choice framework, also standalone), `pride` (contrarian review), `verify` (evidence discipline and Done criteria), `resume`, and `stop`. No hard deps on personal or team skills. |
| **bonsai** | `/bonsai` | | | Worktree lifecycle manager: create a worktree + Claude session in a new iTerm2 pane, or prune worktrees with safety checks. Requires macOS + iTerm2. |
| **clipboard** | `/clipboard` | | | Copy the core content of the last answer to the clipboard. `/clipboard slack` for rich text. |
| **commit-all-the-things** | `/commit-all-the-things` | | | Commit all uncommitted changes in the working tree, grouped into logical commits with descriptive messages. |
| **dont-do-that** | ❌ | | ✅ | Eight guardrail hooks that push back on common AI reflexes: shifting blame, stopping prematurely, delegating verification, and em-dashes in prose. See [dont-do-that](packages/dont-do-that/README.md). |
| **export-skill** | `/export-skill` | | | Export a skill for sharing. Orchestrator that chains five sub-skills, each also user-invocable on its own: `sanitize` (PII + security), `translate` (en/nl), `port` (linux/windows/macos), `package` (zip or single-file md), `share` (clipboard summary + Finder handoff). |
| **eye-of-the-beholder** | `/eye-of-the-beholder` | ✅ | | Catches cramped text, missing margins, and disproportionate spacing in visual layouts (screen, print, responsive). |
| **ground** | `/ground` | ✅ | | Verify Claude's recent output with external sources when you challenge accuracy. |
| **gurus** | `/gurus` | | | Opinionated code review panel with 8 expert perspectives (Beck, Fowler, Uncle Bob, DHH, Metz, Lutke, Hickey, Thoughtbot). |
| **how-plugins-work** | `/how-plugins-work` | ✅ | | Living document explaining how Claude Code plugin naming, skill resolution, and the plugin:skill invocation pattern work. |
| **inspiratie** | `/inspiratie` | ✅ | | Online research workflow for unfamiliar topics, design decisions, and evaluating approaches. |
| **rebase-latest-default** | `/rebase-latest-default` | | | Rebase current branch on the latest default branch (local or remote) with staleness check and automatic conflict resolution. |
| **recap** | `/recap` | | | Structured status overview of the current session: what we're doing, where we are, what's next. |
| **recursion** | `/recursion` | | | Nightly workflow-improvement loop. Orchestrator manages schedule, state, focus, reject. Ships with an internal `research` sub-skill that runs parallel friction and external discovery agents, synthesizes findings, and writes atomic improvement plans. |
| **rename-suggestion** | `/rename-suggestion` | | | Suggest a descriptive session name based on conversation context. |
| **saysay** | `/saysay` | | | Claude speaks every response aloud. `/saysay off` to exit. |
| **screen-recording** | `/screen-recording` | ✅ | | Automated screen recordings and demo videos of browser-based features. |
| **self-improvement** | `/self-improvement` | | | Update CLAUDE.md and skills based on feedback. Detects duplication and extracts large sections into skills. |
| **testing-philosophy** | ❌ | ✅ | | Opinionated testing guide covering TDD workflow, Cucumber/Gherkin, flaky test diagnosis, and test suite health. |
| **whywhy** | `/whywhy [n]` | ✅ | | Drill N layers deep into a question or goal (default 7), then analyze the chain for a better direction. |

## Platform notes

Some skills require macOS-specific tools:

### clipboard

Rich text mode (`/clipboard slack`) requires `pbcopy-html`, a Swift script shipped with the plugin:

```bash
ln -s "$(pwd)/packages/clipboard/skills/clipboard/pbcopy-html.swift" /usr/local/bin/pbcopy-html
```

Plain text mode uses the built-in `pbcopy` and works out of the box on macOS.

### saysay

Speech mode requires macOS `say` and two scripts shipped with the plugin:

```bash
ln -s "$(pwd)/packages/saysay/skills/saysay/saysay" /usr/local/bin/saysay
ln -s "$(pwd)/packages/saysay/skills/saysay/say-phonetic" /usr/local/bin/say-phonetic
```

Phonetic mappings are stored per user in `~/.local/share/saysay/phonetics.json` (XDG).

### screen-recording

Requires [Playwright](https://playwright.dev/) installed globally:

```bash
npm install -g playwright
```

### bonsai

Requires macOS + iTerm2. `/bonsai new` opens a new iTerm2 pane via `osascript`, which is macOS-only. `/bonsai prune` works anywhere git runs.

If you use a wrapper around `claude` (custom alias, flags, model pinning), expose it via the `CLAUDE_CLI` env var in your shell rc:

```bash
export CLAUDE_CLI=my-wrapper
```

Bonsai falls back to `claude` if the var is not set.

## Authoring a new plugin

Two rules that keep plugins portable across Mac, Linux, and Windows:

1. **No symlinks anywhere in the repo.** Pre-commit and CI reject them. Git for Windows defaults to `core.symlinks=false` and turns symlinks into text files on clone; a symlinked skill silently disappears. Every skill lives in exactly one place: `packages/<plugin>/skills/<skill>/`.

2. **Consumer-facing scripts under `packages/<plugin>/bin/` must use a portable shebang.** Only `#!/usr/bin/env node` and `#!/usr/bin/env python3` are accepted. The pre-commit hook rejects anything else and tells you what to port to. Operator-only scripts under repo-root `bin/` can use any shebang.

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
