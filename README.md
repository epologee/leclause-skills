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

| Plugin | Command | Auto | Hooks | Platform | Description |
|--------|---------|:----:|:-----:|:--------:|-------------|
| **autonomous** | `/autonomous:rover`, `/autonomous:prepare` | | | | Dispatch a rover at a task. You stay back, the rover works in the field; the distance means it decides autonomously. Ships with nine skills: `rover` (entry), `rover-help` (briefing), `prepare` (lay a loop file in another repo for later wake), `cron` (scheduling + backoff), `decide` (choice framework, also standalone), `pride` (contrarian review), `verify` (evidence discipline and Done criteria), `wake`, and `stop`. No hard deps on personal or team skills. |
| **bonsai** | `/bonsai` | | | macOS | Worktree lifecycle manager: create a worktree and put a `cd <worktree> && claude "..."` start command on the clipboard so you can paste it into any terminal pane/tab/app, or prune worktrees with safety checks. Requires macOS (uses `pbcopy`). |
| **clipboard** | `/clipboard` | | | macOS | Copy the core content of the last answer to the clipboard via the `clipboard-copy` helper. `/clipboard slack` for rich text. |
| **dont-do-that** | ❌ | | ✅ | | Ten guardrail hooks (one dispatcher, uniform `[dont-do-that/<code>]` messages) that push back on common AI reflexes: shifting blame, stopping prematurely, delegating verification, asking for confirmation when none was needed, sloppy commit-message format, and em-dashes in prose. See [dont-do-that](packages/dont-do-that/README.md). |
| **export-skill** | `/export-skill` | | | macOS | Export a skill for sharing. Orchestrator that chains five sub-skills, each also user-invocable on its own: `sanitize` (PII + security), `translate` (en/nl), `port` (linux/windows/macos), `package` (zip or single-file md), `share` (clipboard summary + Finder handoff). The `share` sub-skill is macOS-only; the others run anywhere. |
| **eye-of-the-beholder** | `/eye-of-the-beholder`, `/art-director` | ✅ | | | Two sister skills. `eye-of-the-beholder` catches cramped text, missing margins, and disproportionate spacing in visual layouts (diagnostic, per-change). `art-director` works upstream: captures brand identity, visual language across type / color / form / motion / photography, and design-system architecture (Curtis 3-layer tokens + Frost atomic components) BEFORE CSS exists. Not for small UI tweaks; for new products, brand refreshes, or first-time DS foundation. |
| **gitgit** | `/gitgit:commit-all-the-things`, `/gitgit:commit-snipe`, `/gitgit:rebase-latest-default`, `/gitgit:merge-to-default`, `/gitgit:commit-discipline`, `/gitgit:install-hooks`, `/gitgit:run-spec`, `/gitgit:disable-discipline`, `/gitgit:enable-discipline`, `/gitgit:discipline-status` | ✅ | ✅ | | Bundle of git-write skills plus a two-layer commit-discipline hook stack. The four day-to-day commands (`commit-all-the-things`, `commit-snipe`, `rebase-latest-default`, `merge-to-default`) cover staging, sniping, rebasing, and landing the current branch on the project default with a github-style `--no-ff` merge. The discipline layer enforces a structured body schema (subject + WHY paragraph + `Slice` / `Tests` / `Red-then-green` / `Visual` trailers parsed via `git interpret-trailers`) on both Claude-driven commits (PreToolUse:Bash dispatcher) and CLI commits (git-native `commit-msg`, `prepare-commit-msg`, `post-commit`, `pre-push` hooks installed per repo via `/gitgit:install-hooks`). Eight `Slice` opt-out tokens (`docs-only`, `config-only`, `migration-only`, `spec-only`, `chore-deps`, `revert`, `merge`, `wip`) plus four logged escape-hatches (`# vsd-skip`, `--no-verify`, `GITGIT_ALLOW_AI_COAUTHOR`, `GITGIT_ALLOW_WIP_PUSH` / `# allow-wip-push`, `GITGIT_TRIVIAL_OK`); `wip` commits are accepted locally but blocked at push time. `Red-then-green: yes` is self-attestation; no cache backs it. `Visual:` is gated by a UI-touch heuristic that scans the staged diff (web-template / styling / iOS storyboard, asset-catalog, and `.swift` files containing SwiftUI / UIKit / AppKit symbols); backend-only commits never see the rule, and false positives are absorbed via `Visual: n/a (reason)`. `/gitgit:run-spec` detects the project's test runner and prints PASS/FAIL without recording evidence. `/gitgit:commit-discipline` is the canonical reference for the schema, error codes, opt-out matrix, and troubleshooting. `/gitgit:disable-discipline` / `/gitgit:enable-discipline` toggle the PreToolUse guards for the current session via a sentinel file in `~/.claude/var/`; `/gitgit:discipline-status` reports the current state. See [gitgit](packages/gitgit/README.md). |
| **ground** | `/ground` | ✅ | | | Verify Claude's recent output with external sources when you challenge accuracy. |
| **gurus** | `/gurus`, `/gurus:software`, `/gurus:council` | | | | Opinionated panels that challenge a decision from multiple perspectives. `gurus:software` hosts the eight-persona code review panel (Beck, Fowler, Uncle Bob, DHH, Metz, Lutke, Hickey, Thoughtbot). `gurus:council` runs Ole Lehmann's five-advisor pattern (pre-mortem, first-principles, opportunity-finder, stranger, action) with anonymised peer-review and chairman synthesis. `/gurus` is an orchestrator that routes between the two panels based on context; it is not itself a review. All voices run on the shared `gurus:sonnet-max` subagent. |
| **how-plugins-work** | `/how-plugins-work`, `/how-plugins-work:test-before-push` | ✅ | | | Living document explaining how Claude Code plugin naming, skill resolution, and the plugin:skill invocation pattern work. The `test-before-push` sub-skill encodes the canonical procedure for pointing a marketplace alias at the local working copy so you can test a plugin change in a fresh Claude session without pushing first. |
| **inspiratie** | `/inspiratie` | ✅ | | | Online research workflow for unfamiliar topics, design decisions, and evaluating approaches. |
| **leclause** | `/leclause:whats-new` | | | | Marketplace-wide utilities. Currently ships `whats-new`, a one-stop reader for the post-update CHANGELOG section of any installed leclause plugin. Argument is the plugin name (`/leclause:whats-new gitgit`); without argument, lists every leclause plugin that adopted the broadcast pattern. The reader uses `--force`, so it never advances the per-plugin sentinel under `~/.claude/var/leclause/`. |
| **recap** | `/recap` | | | | Structured status overview of the current session: what we are doing, where we are, what is next. |
| **recursion** | `/recursion` | | | | Nightly workflow-improvement loop. Orchestrator manages schedule, state, focus, reject. Ships with an internal `research` sub-skill that runs parallel friction and external discovery agents, synthesizes findings, and writes atomic improvement plans. |
| **rename-suggestion** | `/rename-suggestion` | | | | Suggest a descriptive session name based on conversation context. Portable; the macOS-only `clipboard-copy` helper is invoked when present, and on other platforms the ghost-text suggestion still works without the clipboard step. |
| **saysay** | `/saysay` | | | macOS | Claude speaks every response aloud. `/saysay off` to exit. |
| **screen-recording** | `/screen-recording` | | | | Automated screen recordings and demo videos of browser-based features. |
| **self-improvement** | `/self-improvement` | | | | Update CLAUDE.md and skills based on feedback. Detects duplication and extracts large sections into skills. |
| **testing-philosophy** | ❌ | ✅ | | | Opinionated testing guide covering TDD workflow, Cucumber/Gherkin, flaky test diagnosis, and test suite health. |
| **whywhy** | `/whywhy [n]` | ✅ | | | Drill N layers deep into a question or goal (default 7), then analyze the chain for a better direction. |

**Auto column:** skills with a check in this column self-activate when Claude matches the skill's `description` frontmatter against the conversation context. No hook is involved, no separate frontmatter flag; Claude reads the description and decides whether the skill fits the current task.

**Platform column:** blank for cross-platform skills; a value names the only platform the skill has been built and tested against.

## Platform notes

Some skills ship helper binaries that must live on your `$PATH`. Install them with `cp -f` from the active plugin install into `/usr/local/bin/` (or anywhere else on `$PATH`). Symlinks would reintroduce the Windows breakage the marketplace is symlink-free to avoid, so every install step below is a copy.

The authoritative source for "which plugin version is active right now" is `~/.claude/plugins/installed_plugins.json`. Each install step below resolves the install path from that file via `jq`, so it always picks the version Claude Code is currently loading rather than the newest directory in the cache. Re-run the `cp -f` commands after each `claude plugins update <plugin>@leclause` so the installed binaries match the updated plugin.

### clipboard

The `clipboard-copy` helper ships as a Node script at `bin/clipboard-copy` inside the plugin, so it lands in the install cache and skill code invokes it via a `jq`-resolved path. No install step is needed for plain clipboard copies.

Rich text mode (`/clipboard slack`) drives `pbcopy-html`, a Swift script that `clipboard-copy --html` runs from its neighbouring `skills/clipboard/` directory. Copy it onto your `$PATH` if you want to invoke `pbcopy-html` directly from a shell:

```bash
SRC=$(jq -r '.plugins["clipboard@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)
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

`gitgit` is the reference implementation. To adopt the pattern in another plugin:

1. Copy `packages/gitgit/bin/check-broadcast` into `packages/<plugin>/bin/check-broadcast`. The script is plugin-agnostic; it reads the active `name` and `version` from `.claude-plugin/plugin.json` and namespaces the sentinel by plugin name.
2. Add a `CHANGELOG.md` at `packages/<plugin>/CHANGELOG.md`. Each release is a `## [vX.Y.Z]` section with `### Breaking`, `### Added`, `### Changed`, `### Fixed` subheadings as needed. The helper extracts the top-most section in document order, so patch bumps without an entry stay silent without forcing a placeholder.
3. Add a `<post-update-broadcast>` block at the top of the most-frequently-loaded user-invocable skill (typically the plugin's main verb). The block instructs Claude to run `node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"`, show non-empty output verbatim with one short framing sentence, and proceed silently otherwise. See `packages/gitgit/skills/commit-all-the-things/SKILL.md` for the canonical wording.
4. No per-plugin `whats-new` skill is needed. The shared `/leclause:whats-new <plugin>` command (from the `leclause` plugin) reprints the section on demand, regardless of whether the broadcast already fired. One slash-command for the whole marketplace; one entry in `/`-autocomplete; one place where the policy lives.

The sentinel lives at `~/.claude/var/leclause/<plugin>-broadcast-seen` and stores the last-broadcast plugin version. The directory is shared across all leclause plugins so the user can audit it in one place. The helper writes the sentinel only on a non-empty broadcast, so a missing CHANGELOG entry never marks the version as seen.

### What belongs in a broadcast

- **Breaking** (renamed or removed slash commands, hook gates that block previously-accepted input, deprecations with a removal date), **notable Added** (new slash command, new hook event the user can plug into, new opt-out token), **Security** advisories. Always written in user-impact, never in implementation terms. Phrase Breaking entries at the top so the user cannot miss them.
- **Not in a broadcast:** internal refactors, silent bug fixes the user never saw, "various improvements", performance tweaks without observable behavior change, doc-only or test-only commits, language-of-implementation changes, marketing or cross-promotion, donation requests, telemetry-opt-in prompts. Plugins that broadcast these accumulate the same fatigue npm post-install messages caused; treat the broadcast budget like a feature-development budget.
- **Volgordecriterium:** the user MUST NOT be surprised by breaking changes; non-breaking additions can be a soft nudge; never gate the user's actual work on acknowledgement.

The single test for inclusion: would the user benefit from knowing this before their next slash invocation. If the answer is no, leave it out; the next entry above it stays the latest section and the broadcast stays silent until something genuinely worth saying lands.
