# Lecl(a)use Skills

A curated subset of the skills I built while developing applications in Ruby, Swift, Go, JavaScript, Python, Kotlin, and others across various projects. These are the ones I managed to make reusable for colleagues and friends.

I typically prompt in Dutch but write English code, so these skills are a mix of both. The `export-skill` skill can translate if needed.

## Install

macOS and Linux:

```bash
claude plugins marketplace add epologee/leclause-skills
claude plugins install <skill-name>@leclause
```

Windows:

```bash
claude plugins marketplace add epologee/leclause-skills@release
claude plugins install <skill-name>@leclause
```

In both blocks, the second command's `@leclause` is the marketplace alias that the first command sets up (from `.claude-plugin/marketplace.json`'s `name` field), not a branch ref. The first command is where you choose the branch: default branch for macOS/Linux, `@release` for Windows.

The `@release` branch carries the same plugins as `main` but with every symlink replaced by its target content. Git for Windows defaults to `core.symlinks=false` and turns symlinks into text files on clone; the release branch sidesteps that. See [`docs/release-workflow.md`](docs/release-workflow.md) for how the release branch is built and kept in sync with main.

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

Rich text mode (`/clipboard slack`) requires `pbcopy-html`, a Swift script included in `skills/clipboard/`:

```bash
ln -s "$(pwd)/skills/clipboard/pbcopy-html.swift" /usr/local/bin/pbcopy-html
```

Plain text mode uses the built-in `pbcopy` and works out of the box on macOS.

### saysay

Speech mode requires macOS `say` and two scripts included in `skills/saysay/`:

```bash
ln -s "$(pwd)/skills/saysay/saysay" /usr/local/bin/saysay
ln -s "$(pwd)/skills/saysay/say-phonetic" /usr/local/bin/say-phonetic
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

The two rules that keep plugins working on Mac and Windows from day one:

1. **Consumer-facing scripts under `packages/<plugin>/bin/` must use a portable shebang.** Only `#!/usr/bin/env node`, `#!/usr/bin/env python3`, and `#!/usr/bin/env pwsh` are accepted. The pre-commit hook rejects anything else and tells you what to port to. Operator-only scripts under repo-root `bin/` can use any shebang.

2. **Push to `main` and CI republishes `release` automatically.** The `release-branch` GitHub Action runs `bin/marketplace-release --write` on every push to `main`. Windows consumers catch up without any manual step. Run the script by hand only when debugging or publishing outside the normal flow; see [`docs/release-workflow.md`](docs/release-workflow.md).

Symlinks inside the plugin tree (for example, sharing a skill from the repo's top-level `skills/` directory) are fine on `main`. The release branch materialises them so Windows consumers never see a symlink.

## Plugin versioning

Every plugin's version in `packages/<name>/.claude-plugin/plugin.json` follows the format `1.0.{commits}`, where `commits` is the number of commits that touched `packages/<name>/` or `skills/<name>/`. Versions bump automatically via the repo's pre-commit hook.

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
