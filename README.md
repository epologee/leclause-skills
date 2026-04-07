# Leclause Skills

A collection of skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Install individual skills or the complete collection.

## Install

```bash
claude plugins marketplace add epologee/leclause-skills
claude plugins install <skill-name>@leclause
```

## Skills

### Slash commands

Skills you invoke explicitly with `/<name>`:

| Skill | Command | Description |
|-------|---------|-------------|
| **clipboard** | `/clipboard` | Copy the core content of the last answer to the macOS clipboard via pbcopy. Supports `/clipboard slack` for rich text. |
| **commit-all-the-things** | `/commit-all-the-things` | Commit all uncommitted changes in the working tree, grouped into logical commits with descriptive messages. |
| **export-skill** | `/export-skill` | Export and sanitize a skill for sharing, stripping PII and checking for security issues. Supports translation and platform porting. |
| **ground** | `/ground` | Verify Claude's recent output with external sources when you challenge accuracy or say "dat klopt niet". |
| **gurus** | `/gurus` | Opinionated code review panel with 8 expert perspectives (Beck, Fowler, Uncle Bob, DHH, Metz, Lutke, Hickey, Thoughtbot). |
| **inspiratie** | `/inspiratie` | Online research workflow for unfamiliar topics, design decisions, and evaluating approaches. |
| **rebase-origin-default** | `/rebase-origin-default` | Safely rebase current branch on the remote default branch with staleness check and automatic conflict resolution. |
| **recap** | `/recap` | Structured status overview of the current session: what we're doing, where we are, what's next. |
| **recursion** | `/recursion` | Deep research producing atomic improvement plans for the Claude Code workflow. |
| **rename-suggestion** | `/rename-suggestion` | Generate a descriptive session name based on conversation context and copy the rename command to clipboard. |
| **saysay** | `/saysay` | Speech mode via macOS `say`. Claude speaks output aloud after every response. `/saysay off` to exit. |
| **screen-recording** | `/screen-recording` | Automated screen recordings and demo videos of browser-based features using Playwright. |
| **self-improvement** | `/self-improvement` | Update CLAUDE.md and skills based on feedback. Detects duplication and extracts large sections into skills. |
| **whywhy** | `/whywhy [n]` | Drill N layers deep into a question or goal (default 7). Claude autonomously asks and answers "why?" N times, then analyzes the chain. |
| **how-plugins-work** | `/how-plugins-work` | Living document explaining how Claude Code plugin naming, skill resolution, and the plugin:skill invocation pattern work. |

### Also auto-triggered

All skills above are slash commands. The skills below are too (`/eye-of-the-beholder`, `/testing-philosophy`), but they also activate automatically based on context:

| Skill | Triggers on |
|-------|-------------|
| **eye-of-the-beholder** | Producing or reviewing any visual layout (screen, print, responsive). Catches cramped text, missing margins, disproportionate spacing. |
| **testing-philosophy** | Writing tests, debugging test failures, reviewing test strategy. Covers TDD workflow, Cucumber/Gherkin, flaky tests, and test suite health. |

## Hook plugins

Plugins that install Claude Code hooks instead of skills. They run automatically on tool calls or session events.

| Plugin | What it guards against |
|--------|------------------------|
| **dont-do-that** | Six guardrail hooks that push back on common AI reflexes: shifting blame, stopping prematurely, delegating verification, asking for confirmation when none was needed, and em-dashes in prose. See [packages/dont-do-that/README.md](packages/dont-do-that/README.md) for the full list. |

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

## Plugin versioning

Every plugin's version in `packages/<name>/.claude-plugin/plugin.json` follows the format `1.0.{commits}`, where `commits` is the number of commits that touched `packages/<name>/` or `skills/<name>/`. A plugin's version therefore monotonically increases with each change to that plugin, independent of the other plugins in this marketplace.

Enforcement runs automatically via the repo-level `hooks/pre-commit` script (activated with `git config core.hooksPath hooks`), which calls `bin/plugin-versions --staged` on every `git commit` after staging. When you change a plugin, its version bumps and the new `plugin.json` is staged alongside your other changes. The same script keeps `marketplace.json` plugin descriptions in sync with each `plugin.json`.

Recovery after rebase or manual edits:

```bash
bin/plugin-versions --check   # Report drift
bin/plugin-versions --write   # Fix drift
```

## Contributing

Skills are developed locally and moved to this repo when ready. See [CLAUDE.md](CLAUDE.md) for development workflow, commit conventions, and the PII sanitization checklist.
