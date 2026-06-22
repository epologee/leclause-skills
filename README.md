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

Then install replacements one plugin at a time:

```bash
claude plugins install how-plugins-work@laicluse-agent-fieldkit
claude plugins install git-discipline@laicluse-agent-fieldkit
claude plugins install self-improvement@laicluse-agent-fieldkit
claude plugins install intervision@laicluse-agent-fieldkit
claude plugins install anger-management@laicluse-agent-fieldkit
claude plugins install rover@laicluse-agent-fieldkit
claude plugins install autonomous@laicluse-agent-fieldkit
claude plugins install clipboard@laicluse-agent-fieldkit
```

Keep `@leclause` installed until every plugin you use has either been replaced
or deliberately removed. Do not run `claude plugins marketplace remove
leclause` as the first migration step: removing the marketplace from its last
scope also uninstalls the plugins that came from it.

Current replacements:

| Old plugin | New plugin |
|------------|------------|
| `how-plugins-work@leclause` | `how-plugins-work@laicluse-agent-fieldkit` |
| `gitgit@leclause` | `git-discipline@laicluse-agent-fieldkit` |
| `self-improvement@leclause` | `self-improvement@laicluse-agent-fieldkit` |
| `intervision@leclause` | `intervision@laicluse-agent-fieldkit` |
| `anger-management@leclause` | `anger-management@laicluse-agent-fieldkit` |
| `autonomous@leclause` | split: `rover@laicluse-agent-fieldkit` (mission framework, `/rover:*`) + `autonomous@laicluse-agent-fieldkit` (keepalive layer) |
| `clipboard@leclause` | `clipboard@laicluse-agent-fieldkit` |

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
| **bonsai** | `/bonsai` | | | macOS | Worktree lifecycle manager: create a worktree and put a `cd <worktree> && claude "..."` start command on the clipboard so you can paste it into any terminal pane/tab/app, or prune worktrees with safety checks. Requires macOS (uses `pbcopy`). |
| **clipboard** | ❌ deprecated | | | | **DEPRECATED. Moved to `clipboard@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The commands are unchanged in the successor (`/clipboard`, `/clipboard slack`). Install `clipboard@laicluse-agent-fieldkit`, then `claude plugins uninstall clipboard@leclause`. See [clipboard](packages/clipboard/README.md). |
| **dont-do-that** | `/duh`, `/just-a-question` | | ✅ | | Guardrail hooks (one dispatcher, uniform `[dont-do-that/<code>]` messages) that push back on common AI reflexes: shifting blame, stopping prematurely, delegating verification, offering a recipe instead of executing it (`duh` guard), asking for confirmation when none was needed, handing back a bare option menu instead of a reasoned, emoji-marked pick (`prefer` guard at Stop detects lettered `(a)`/`(b)` menus, `Optie`/`Option N` lists, choice-column tables, and numbered menus, each gated by a choice signal so status tables and step plans stay silent; runs before the close-out nudges, mark your lean with 🅰️/🅱️ or 1️⃣/2️⃣, escape with 🧭 or 🚧, and gets a `/decide` pointer when `autonomous` is installed), em-dashes in prose, hallucinated hour/day/week effort estimates (`estimate` guard at Stop catches "een paar uur werk", "halve dag uitzoekwerk", "a few days of work", "binnen een uur", and the "option A is vandaag, B is deze week" comparison frame; calendar, cron, retention, SLA, and past-tense phrasing is filtered so legitimate scheduling and history claims pass; escape with `🧭` for deferred judgment, `🚧` for WIP), and adding code comments to programming-language files (`no-code-comments` guard at PreToolUse uses per-language awk tokenizers to distinguish real comments from strings, allow rules for URL, `allow-comment` escape, pragma allowlist, and shebangs). Plus two user-invocable skills: `/duh` is the operator's one-keystroke correction when Claude proposed an action instead of running it; it tells Claude to execute the proposal from the previous turn (or disambiguate when the turn had multiple proposals). `/just-a-question` is the inverse: half of "this is a question for information, not a request for change", which forbids mutation tools for the rest of the turn so a clarifying question cannot tip into mid-question code edits. See [dont-do-that](packages/dont-do-that/README.md). |
| **drydry** | `/drydry:drydry` | | | | Find and converge parallel paths in any artefact (code in any language, prose, design systems, technical documentation). Methodology guide that disciplines how a duplication audit runs (eight chapters: Type-4 clone framing, verifier-burden LLM pass, allow-list scoping, drift hypothesis, three-bucket triage, two-fates discipline, contrarian second-pass, method-as-artefact) without prescribing what duplication looks like in your codebase. One user-invocable orchestrator `drydry:drydry` with two modes: `quick` (inline "is this duplicate?" check with a runnable verifier-grep, no artefact) and `audit` (full sweep producing a `<scope>-drydry-findings.md` artefact with `## Detection method chosen` and `## Findings`). In audit mode the calling session formulates the six-to-ten item checklist itself by reading the codebase against formulation prompts (canonical-channel bypass, parallel utilities, predicate pairs, framework-seam boilerplate, commit-history clusters, user-facing copy variants, parallel UX surfaces, off-template project-specific patterns, parallel orchestrations above a shared leaf-call); drydry disciplines how the list is used, not what is on it. Six agent-only sub-skills: `sweep` (Sonnet detection pass with verifier-burden discipline; hits without a runnable verifier are dropped), `checklist` (opt-in seed source returning starting-point templates per domain when the operator passes `seed-from <domain>`; the session rewrites the seed against the actual codebase before passing it to sweep), `triage` (three-bucket classification: cheap-and-safe / partial / needs-design with convergence cost per item), `learn` (online research on de-duplication state-of-the-art via parallel WebSearch and WebFetch subagents, enriches the discipline's external vocabulary), `upstream` (cross-toolbox audit against framework offerings: Rails/Devise helpers, SwiftUI/Foundation built-ins, React conventions; uses `inspire` and `ground` patterns to verify the framework actually offers what we suspect), `instructions` (CLAUDE.md audit for instructions that themselves cause DRY violations: two paths prescribed for the same job, or silence on existing helpers causing agent-generated parallel code). See [drydry](packages/drydry/README.md). |
| **export-skill** | `/export-skill` | | | macOS | Export a skill for sharing. Orchestrator that chains five sub-skills, each also user-invocable on its own: `sanitize` (PII + security), `translate` (en/nl), `port` (linux/windows/macos), `package` (zip or single-file md), `share` (clipboard summary + Finder handoff). The `share` sub-skill is macOS-only; the others run anywhere. |
| **eye-of-the-beholder** | `/eye-of-the-beholder`, `/art-director`, `/visual-inspection` | ✅ | | | Three sister skills. `eye-of-the-beholder` catches cramped text, missing margins, and disproportionate spacing in visual layouts (diagnostic, per-change). `art-director` works upstream: captures brand identity, visual language across type / color / form / motion / photography, and design-system architecture (Curtis 3-layer tokens + Frost atomic components) BEFORE CSS exists. `visual-inspection` activates when the user asks to match one element to another along named axes (padding, corner radius, font, color); it forces a reference + result screenshot table comparison before "match" can be claimed. Not for small UI tweaks; for new products, brand refreshes, or first-time DS foundation. |
| **gitgit** | ❌ deprecated | | | | **DEPRECATED. Moved to `git-discipline@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills or commit hooks remain. Install `git-discipline@laicluse-agent-fieldkit` (same thirteen skills under the same names, `/git-discipline:` prefix), then `claude plugins uninstall gitgit@leclause`. See [gitgit](packages/gitgit/README.md). |
| **ground** | `/ground` | ✅ | | | Verify Claude's recent output with external sources when you challenge accuracy. |
| **gurus** | `/gurus`, `/gurus:software`, `/gurus:council`, `/gurus:writers` | | | | Opinionated panels that challenge a decision from multiple perspectives. `gurus:software` hosts the eight-persona code review panel (Beck, Fowler, Uncle Bob, DHH, Metz, Evans, Hickey, Ousterhout). `gurus:council` runs Ole Lehmann's five-advisor pattern (pre-mortem, first-principles, opportunity-finder, stranger, action) with anonymised peer-review and chairman synthesis. `gurus:writers` runs a six-writer prose review panel (Didion, Saunders, Rovelli, Watts, Gladwell, Urban) for essays, scripts, manuscripts, and narrative copy; consensus across 4 of 6 yields an action plan of edits, cuts, and rewrites. `/gurus` is an orchestrator that routes between the three panels based on context; it is not itself a review. All voices run on the shared `gurus:sonnet-max` subagent. |
| **how-plugins-work** | ❌ deprecated | | | | **DEPRECATED. Moved to `how-plugins-work@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill names, so the slash commands stay identical. Install `how-plugins-work@laicluse-agent-fieldkit`, then `claude plugins uninstall how-plugins-work@leclause`. See [how-plugins-work](packages/how-plugins-work/README.md). |
| **inspire** | `/inspire` | ✅ | | | Online research workflow for unfamiliar topics, design decisions, and evaluating approaches. |
| **intervision** | ❌ deprecated | | | | **DEPRECATED. Moved to `intervision@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill name (slash command stays `/intervision:second-opinion`) and is multi-agent: Claude consults Codex via `codex exec`, Codex consults Claude via `claude -p`. Install `intervision@laicluse-agent-fieldkit`, then `claude plugins uninstall intervision@leclause`. See [intervision](packages/intervision/README.md). |
| **leclause** | `/leclause:whats-new` | | | | Marketplace-wide utilities. Currently ships `whats-new`, a one-stop reader for the post-update CHANGELOG section of any installed leclause plugin. Argument is the plugin name (`/leclause:whats-new gitgit`); without argument, lists every leclause plugin that adopted the broadcast pattern. The reader uses `--force`, so it never advances the per-plugin sentinel under `~/.claude/var/leclause/`. |
| **anger-management** | ❌ deprecated | | | | **DEPRECATED. Moved to `anger-management@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill names (slash commands stay identical) and is multi-agent; the friction pile moves to `${LAICLUSE_HOME:-~/.laicluse}/anger-management/` with automatic migration of existing captures. Install `anger-management@laicluse-agent-fieldkit`, then `claude plugins uninstall anger-management@leclause`. See [anger-management](packages/anger-management/README.md). |
| **recap** | `/recap` | | | | Structured status overview of the current session: what we are doing, where we are, what is next. |
| **recursion** | `/recursion` | | | | Nightly workflow-improvement loop. Orchestrator manages schedule, state, focus, reject. Ships with an internal `research` sub-skill that runs parallel friction and external discovery agents, synthesizes findings, and writes atomic improvement plans. |
| **rename-suggestion** | ❌ end of life | | | | **END OF LIFE. Discontinued without a successor.** Now a tombstone that ships only a SessionStart notice; no skills remain. Run `claude plugins uninstall rename-suggestion@leclause`. The idea needs no plugin: ask your agent for a short descriptive session name ending in a `/rename <name>` line. See [rename-suggestion](packages/rename-suggestion/README.md). |
| **saysay** | `/saysay` | | | macOS | Claude speaks every response aloud. `/saysay off` to exit. |
| **self-improvement** | ❌ deprecated | | | | **DEPRECATED. Moved to `self-improvement@laicluse-agent-fieldkit`.** Now a tombstone that ships only a SessionStart migration notice; no skills remain. The successor keeps the same plugin and skill name, so the slash command stays `/self-improvement`. Install `self-improvement@laicluse-agent-fieldkit`, then `claude plugins uninstall self-improvement@leclause`. See [self-improvement](packages/self-improvement/README.md). |
| **screen-recording** | `/screen-recording` | | | | Automated screen recordings and demo videos of browser-based features. |
| **testing-philosophy** | ❌ | ✅ | | | Opinionated testing guide covering TDD workflow, end-to-end behaviour-test conventions (Cucumber/Gherkin and other framework choices), flaky test diagnosis, and test suite health. |
| **whywhy** | `/whywhy [n]` | ✅ | | | Drill N layers deep into a question or goal (default 10), then analyze the chain for a better direction. |

**Auto column:** skills with a check in this column self-activate when Claude matches the skill's `description` frontmatter against the conversation context. No hook is involved, no separate frontmatter flag; Claude reads the description and decides whether the skill fits the current task.

**Platform column:** blank for cross-platform skills; a value names the only platform the skill has been built and tested against.

## Platform notes

Some skills ship helper binaries that must live on your `$PATH`. Install them with `cp -f` from the active plugin install into `/usr/local/bin/` (or anywhere else on `$PATH`). Symlinks would reintroduce the Windows breakage the marketplace is symlink-free to avoid, so every install step below is a copy.

The authoritative source for "which plugin version is active right now" is `~/.claude/plugins/installed_plugins.json`. Each install step below resolves the install path from that file via `jq`, so it always picks the version Claude Code is currently loading rather than the newest directory in the cache. Re-run the `cp -f` commands after each `claude plugins update <plugin>@leclause` so the installed binaries match the updated plugin.

### clipboard

Moved to `clipboard@laicluse-agent-fieldkit`; the helper install notes live in
that package's README. The `pbcopy-html` PATH copy keys on the successor:

```bash
SRC=$(jq -r '.plugins["clipboard@laicluse-agent-fieldkit"][0].installPath' ~/.claude/plugins/installed_plugins.json)
cp -f "$SRC/skills/clipboard/pbcopy-html.swift" /usr/local/bin/pbcopy-html
```

Plain text mode goes through `pbcopy` directly, no install needed.

### saysay

Speech mode requires the macOS `say` binary plus two scripts shipped with the plugin:

```bash
SRC=$(jq -r '.plugins["saysay@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)
cp -f "$SRC/skills/saysay/saysay" /usr/local/bin/saysay
cp -f "$SRC/skills/saysay/say-phonetic" /usr/local/bin/say-phonetic
```

Phonetic mappings are stored per user in `~/.local/share/saysay/phonetics.json` (XDG).

### screen-recording

Requires [Playwright](https://playwright.dev/) installed globally:

```bash
npm install -g playwright
```

The skill is not auto-activated: self-activation on description match without that dependency would fail silently, so `/screen-recording` must be invoked explicitly after the install.

### bonsai

Requires macOS. `/bonsai new` puts the start command on the clipboard via `pbcopy`, which is macOS-only. `/bonsai prune` works anywhere git runs. Terminal-app agnostic: paste the command into iTerm2, Terminal.app, cmux, Ghostty, Warp, a tmux pane, whatever.

If you use a wrapper around `claude` (custom alias, flags, model pinning), expose it via the `CLAUDE_CLI` env var in your shell rc:

```bash
export CLAUDE_CLI=my-wrapper
```

Bonsai puts the literal string `${CLAUDE_CLI:-claude}` in the clipboard command so the target shell evaluates it at paste time, falling back to `claude` if the var is not set.

## Post-update broadcasts

Plugins in this marketplace can ship a one-off broadcast that fires the next time the user runs one of the plugin's slash commands after `claude plugins update`. Use it to announce renames, new commands, breaking hook changes, or deprecation warnings. Patch-level fixes that change nothing observable are intentionally silent.

All plugins in this marketplace ship the broadcast pattern, with two exceptions: `testing-philosophy` (referenced via the Skill tool only, no slash command for the broadcast to attach to) and the deprecated tombstones (`gitgit`, `self-improvement`, `how-plugins-work`, `intervision`, `anger-management`, `autonomous`), which carry no changelog because their SessionStart notice is their only remaining output. The `bin/check-broadcast` helper has a single canonical source at `bin/check-broadcast.mjs` in the repo root; every plugin's `bin/check-broadcast` is a byte-for-byte mirror, kept in sync by `bin/sync-check-broadcast` and policed by the pre-commit hook. Plugin authors do not edit per-plugin copies; they edit the canonical, then run the sync.

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
