# Lecl(a)use Skills

A curated subset of the skills I built while developing applications in Ruby, Swift, Go, JavaScript, Python, Kotlin, and others across various projects. These are the ones I managed to make reusable for colleagues and friends.

I typically prompt in Dutch but write English code, so these skills are a mix of both. The `export-skill` skill can translate if needed.

## Maintenance mode: l'Aicluse migration

This marketplace is entering maintenance mode. New multi-agent-compatible
versions of selected tools are moving to `epologee/laicluse-agent-fieldkit` under
the marketplace alias `@laicluse-agent-fieldkit`.

Add the successor marketplace first:

```bash
claude plugins marketplace add epologee/laicluse-agent-fieldkit
```

Then install replacements one plugin at a time, using the mapping below:

```bash
claude plugins install <new-plugin>@laicluse-agent-fieldkit
claude plugins uninstall <old-plugin>@leclause
```

Keep `@leclause` installed until every plugin you use has either been replaced
or deliberately removed. Do not run `claude plugins marketplace remove
leclause` as the first migration step: removing the marketplace from its last
scope also uninstalls the plugins that came from it.

Current replacements:

| Old plugin | New plugin |
|------------|------------|
| `anger-management@leclause` | `anger-management@laicluse-agent-fieldkit` |
| `autonomous@leclause` | split: `rover@laicluse-agent-fieldkit` (mission framework, `/rover:*`) + `autonomous@laicluse-agent-fieldkit` (keepalive layer) |
| `bonsai@leclause` | `bonsai@laicluse-agent-fieldkit` |
| `clipboard@leclause` | `clipboard@laicluse-agent-fieldkit` |
| `dont-do-that@leclause` | `dont-do-that@laicluse-agent-fieldkit` |
| `drydry@leclause` | `drydry@laicluse-agent-fieldkit` |
| `eye-of-the-beholder@leclause` | `eye-of-the-beholder@laicluse-agent-fieldkit` |
| `ground@leclause` | `lifeline@laicluse-agent-fieldkit` |
| `gurus@leclause` | `gurus@laicluse-agent-fieldkit` |
| `how-plugins-work@leclause` | `how-plugins-work@laicluse-agent-fieldkit` |
| `gitgit@leclause` | `git-discipline@laicluse-agent-fieldkit` |
| `inspire@leclause` | `lifeline@laicluse-agent-fieldkit` |
| `intervision@leclause` | `intervision@laicluse-agent-fieldkit` |
| `saysay@leclause` | `saysay@laicluse-agent-fieldkit` |
| `self-improvement@leclause` | `self-improvement@laicluse-agent-fieldkit` |
| `testing-philosophy@leclause` | `house-rules@laicluse-agent-fieldkit` |
| `whywhy@leclause` | `whywhy@laicluse-agent-fieldkit` |

Plugins not listed above remain in `@leclause` for now.

## Install

Same command on macOS, Linux, and Windows:

```bash
claude plugins marketplace add epologee/leclause-skills
claude plugins install <plugin-name>@leclause
```

The `@leclause` suffix in the second command is the marketplace alias that the first command registers (from `.claude-plugin/marketplace.json`'s `name` field), not a branch ref. Every skill lives at its final location under `packages/<plugin>/skills/<skill>/`, so Windows consumers with the default `core.symlinks=false` get working directories out of the box.

## Skills

| Plugin | Command | Auto | Hooks | Platform | Description |
|--------|---------|:----:|:-----:|:--------:|-------------|
| **autonomous** | ❌ deprecated | | | | **DEPRECATED. Split into `rover@laicluse-agent-fieldkit` and `autonomous@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The mission framework lives on as `rover` (`/autonomous:rover` is now `/rover:rover`, same rename for `prepare`, `decide`, `pride`, `trim`, `verify`, `stop`, `rover-help`); the successor `autonomous` keeps only the keepalive/cron/wake layer, which the rover pulls in by itself in interactive sessions. Existing `.autonomous/` loop files stay readable. Install both successors, then `claude plugins uninstall autonomous@leclause`. See [autonomous](packages/autonomous/README.md). |
| **bonsai** | ❌ deprecated | | | | **DEPRECATED. Moved to `bonsai@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install the successor, then `claude plugins uninstall bonsai@leclause`. See [bonsai](packages/bonsai/README.md). |
| **clipboard** | ❌ deprecated | | | | **DEPRECATED. Moved to `clipboard@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The commands are unchanged in the successor (`/clipboard`, `/clipboard slack`). Install `clipboard@laicluse-agent-fieldkit`, then `claude plugins uninstall clipboard@leclause`. See [clipboard](packages/clipboard/README.md). |
| **dont-do-that** | ❌ deprecated | | | | **DEPRECATED. Moved to `dont-do-that@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills or guards remain. Install the successor, then `claude plugins uninstall dont-do-that@leclause`. See [dont-do-that](packages/dont-do-that/README.md). |
| **drydry** | ❌ deprecated | | | | **DEPRECATED. Moved to `drydry@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install the successor, then `claude plugins uninstall drydry@leclause`. See [drydry](packages/drydry/README.md). |
| **export-skill** | `/export-skill` | | | macOS | Export a skill for sharing. Orchestrator that chains five sub-skills, each also user-invocable on its own: `sanitize` (PII + security), `translate` (en/nl), `port` (linux/windows/macos), `package` (zip or single-file md), `share` (clipboard summary + Finder handoff). The `share` sub-skill is macOS-only; the others run anywhere. |
| **eye-of-the-beholder** | ❌ deprecated | | | | **DEPRECATED. Moved to `eye-of-the-beholder@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install the successor, then `claude plugins uninstall eye-of-the-beholder@leclause`. See [eye-of-the-beholder](packages/eye-of-the-beholder/README.md). |
| **gitgit** | ❌ deprecated | | | | **DEPRECATED. Moved to `git-discipline@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills or commit hooks remain. Install `git-discipline@laicluse-agent-fieldkit` (same thirteen skills under the same names, `/git-discipline:` prefix), then `claude plugins uninstall gitgit@leclause`. See [gitgit](packages/gitgit/README.md). |
| **ground** | ❌ deprecated | | | | **DEPRECATED. Moved into `lifeline@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install `lifeline@laicluse-agent-fieldkit`, then uninstall `ground@leclause` and `inspire@leclause`. See [ground](packages/ground/README.md). |
| **gurus** | ❌ deprecated | | | | **DEPRECATED. Moved to `gurus@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills or subagents remain. The four skill names are unchanged. Install the successor, then `claude plugins uninstall gurus@leclause`. See [gurus](packages/gurus/README.md). |
| **how-plugins-work** | ❌ deprecated | | | | **DEPRECATED. Moved to `how-plugins-work@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill names, so the slash commands stay identical. Install `how-plugins-work@laicluse-agent-fieldkit`, then `claude plugins uninstall how-plugins-work@leclause`. See [how-plugins-work](packages/how-plugins-work/README.md). |
| **inspire** | ❌ deprecated | | | | **DEPRECATED. Moved into `lifeline@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install `lifeline@laicluse-agent-fieldkit`, then uninstall `inspire@leclause` and `ground@leclause`. See [inspire](packages/inspire/README.md). |
| **intervision** | ❌ deprecated | | | | **DEPRECATED. Moved to `intervision@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill name (slash command stays `/intervision:second-opinion`) and is multi-agent: Claude consults Codex via `codex exec`, Codex consults Claude via `claude -p`. Install `intervision@laicluse-agent-fieldkit`, then `claude plugins uninstall intervision@leclause`. See [intervision](packages/intervision/README.md). |
| **leclause** | `/leclause:whats-new` | | | | Marketplace-wide utilities. Currently ships `whats-new`, a one-stop reader for the post-update CHANGELOG section of any installed leclause plugin. Argument is the plugin name (`/leclause:whats-new gitgit`); without argument, lists every leclause plugin that adopted the broadcast pattern. The reader uses `--force`, so it never advances the per-plugin sentinel under `~/.claude/var/leclause/`. |
| **anger-management** | ❌ deprecated | | | | **DEPRECATED. Moved to `anger-management@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill names (slash commands stay identical) and is multi-agent; the friction pile moves to `${LAICLUSE_HOME:-~/.laicluse}/anger-management/` with automatic migration of existing captures. Install `anger-management@laicluse-agent-fieldkit`, then `claude plugins uninstall anger-management@leclause`. See [anger-management](packages/anger-management/README.md). |
| **recap** | `/recap` | | | | Structured status overview of the current session: what we are doing, where we are, what is next. |
| **recursion** | `/recursion` | | | | Nightly workflow-improvement loop. Orchestrator manages schedule, state, focus, reject. Ships with an internal `research` sub-skill that runs parallel friction and external discovery agents, synthesizes findings, and writes atomic improvement plans. |
| **rename-suggestion** | ❌ end of life | | | | **END OF LIFE. Discontinued without a successor.** Now a tombstone that ships only a SessionStart notice; no skills remain. Run `claude plugins uninstall rename-suggestion@leclause`. The idea needs no plugin: ask your agent for a short descriptive session name ending in a `/rename <name>` line. See [rename-suggestion](packages/rename-suggestion/README.md). |
| **saysay** | ❌ deprecated | | | | **DEPRECATED. Moved to `saysay@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install the successor, then `claude plugins uninstall saysay@leclause`. See [saysay](packages/saysay/README.md). |
| **self-improvement** | ❌ deprecated | | | | **DEPRECATED. Moved to `self-improvement@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill name, so the slash command stays `/self-improvement`. Install `self-improvement@laicluse-agent-fieldkit`, then `claude plugins uninstall self-improvement@leclause`. See [self-improvement](packages/self-improvement/README.md). |
| **screen-recording** | `/screen-recording` | | | | Automated screen recordings and demo videos of browser-based features. |
| **testing-philosophy** | ❌ deprecated | | | | **DEPRECATED. Moved into `house-rules@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install `house-rules@laicluse-agent-fieldkit`, then `claude plugins uninstall testing-philosophy@leclause`. See [testing-philosophy](packages/testing-philosophy/README.md). |
| **whywhy** | ❌ deprecated | | | | **DEPRECATED. Moved to `whywhy@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. Install the successor, then `claude plugins uninstall whywhy@leclause`. See [whywhy](packages/whywhy/README.md). |

**Auto column:** skills with a check in this column self-activate when Claude matches the skill's `description` frontmatter against the conversation context. No hook is involved, no separate frontmatter flag; Claude reads the description and decides whether the skill fits the current task.

**Platform column:** blank for cross-platform skills; a value names the only platform the skill has been built and tested against.

## Platform notes

Some skills ship helper binaries that must live on your `$PATH`. Install them with `cp -f` from the active plugin install into `/usr/local/bin/` (or anywhere else on `$PATH`). Symlinks would reintroduce the Windows breakage the marketplace is symlink-free to avoid, so every install step below is a copy.

The authoritative source for "which plugin version is active right now" is `~/.claude/plugins/installed_plugins.json`. Each install step below resolves the install path from that file via `jq`, so it always picks the version Claude Code is currently loading rather than the newest directory in the cache. Re-run the `cp -f` commands after each plugin update so the installed binaries match the updated plugin.

### clipboard

Moved to `clipboard@laicluse-agent-fieldkit`; the helper install notes live in
that package's README. The `pbcopy-html` PATH copy keys on the successor:

```bash
SRC=$(jq -r '.plugins["clipboard@laicluse-agent-fieldkit"][0].installPath' ~/.claude/plugins/installed_plugins.json)
cp -f "$SRC/skills/clipboard/pbcopy-html.swift" /usr/local/bin/pbcopy-html
```

Plain text mode goes through `pbcopy` directly, no install needed.

### saysay

Moved to `saysay@laicluse-agent-fieldkit`; the runtime and helper installation notes live in that package's README.

### screen-recording

Requires [Playwright](https://playwright.dev/) installed globally:

```bash
npm install -g playwright
```

The skill is not auto-activated: self-activation on description match without that dependency would fail silently, so `/screen-recording` must be invoked explicitly after the install.

### bonsai

Moved to `bonsai@laicluse-agent-fieldkit`; the cross-platform CLI and worktree setup notes live in that package's README.

## Post-update broadcasts

Plugins in this marketplace can ship a one-off broadcast that fires the next time the user runs one of the plugin's slash commands after `claude plugins update`. Use it to announce renames, new commands, breaking hook changes, or deprecation warnings. Patch-level fixes that change nothing observable are intentionally silent.

Active plugins in this marketplace ship the broadcast pattern when they have an invocable entry skill. Deprecated tombstones carry no changelog because their SessionStart notice is their only remaining output. The `bin/check-broadcast` helper has a single canonical source at `bin/check-broadcast.mjs` in the repo root; every active plugin's `bin/check-broadcast` is a byte-for-byte mirror, kept in sync by `bin/sync-check-broadcast` and policed by the pre-commit hook. Plugin authors do not edit per-plugin copies; they edit the canonical, then run the sync.

To adopt the pattern in a new plugin, run `bin/adopt-broadcast <plugin> [<entry-skill>]` from the repo root. The script writes the CHANGELOG.md skeleton, syncs the canonical helper into the plugin's `bin/`, and prepends the standard `<post-update-broadcast>` block to the named entry skill (defaults to `<plugin>` when `packages/<plugin>/skills/<plugin>/SKILL.md` exists). Re-running on an already-adopted plugin is a no-op except for re-syncing the helper.

The CHANGELOG body is the only piece the author hand-edits. Each release is a `## [vX.Y.Z]` section with `### Breaking`, `### Added`, `### Changed`, `### Fixed` subheadings as needed. The helper extracts the top-most `## [vX.Y.Z]` section in document order, so patch bumps without an entry stay silent without forcing a placeholder. The shared `/leclause:whats-new <plugin>` command (from the `leclause` plugin) reprints the section on demand without touching the sentinel.

The sentinel lives at `~/.claude/var/leclause/<plugin>-broadcast-seen` and stores the last-broadcast plugin version. The directory is shared across all leclause plugins so the user can audit it in one place. The helper writes the sentinel only on a non-empty broadcast, so a missing CHANGELOG entry never marks the version as seen.

### What belongs in a broadcast

- **Breaking** (renamed or removed slash commands, hook gates that block previously-accepted input, deprecations with a removal date), **notable Added** (new slash command, new hook event the user can plug into, new opt-out token), **Security** advisories. Always written in user-impact, never in implementation terms. Phrase Breaking entries at the top so the user cannot miss them.
- **Not in a broadcast:** internal refactors, silent bug fixes the user never saw, "various improvements", performance tweaks without observable behavior change, doc-only or test-only commits, language-of-implementation changes, marketing or cross-promotion, donation requests, telemetry-opt-in prompts. Plugins that broadcast these accumulate the same fatigue npm post-install messages caused; treat the broadcast budget like a feature-development budget.
- **Volgordecriterium:** the user MUST NOT be surprised by breaking changes; non-breaking additions can be a soft nudge; never gate the user's actual work on acknowledgement.

### Length

Each bullet is at most two sentences. The first sentence states the user-visible change; the optional second sentence names the one consequence the user must act on. No back-story about the previous behavior, no explanation of the implementation, no apology for the change. A reader who has never seen the plugin before should be able to skim the entire section in under thirty seconds; if a bullet does not fit that budget, split it into a separate entry or move the rationale into a commit message where it belongs.

A reader who wants the implementation reasoning runs `git log` against the plugin directory; the broadcast is for action-relevant change, not for engineering history.

The single test for inclusion: would the user benefit from knowing this before their next slash invocation. If the answer is no, leave it out; the next entry above it stays the latest section and the broadcast stays silent until something genuinely worth saying lands.
