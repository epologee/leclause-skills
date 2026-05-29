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
| **autonomous** | `/autonomous:rover`, `/autonomous:prepare`, `/autonomous:trim` | | | | Dispatch a rover at a task. You stay back, the rover works in the field; the distance means it decides autonomously. Ships with ten skills: `rover` (entry), `rover-help` (briefing), `prepare` (lay a loop file in another repo for later wake), `cron` (scheduling + backoff), `decide` (choice framework, also standalone), `pride` (contrarian review), `trim` (subtraction-pass before STOW, also standalone), `verify` (evidence discipline and Done criteria), `wake`, and `stop`. Findings raised during INSPECT go through three fates (fix, cost-value-skip with structured rationale, reject-as-non-issue with pride's second-pass evidence); cost here is output weight, not work effort. Hard dep on `gurus@leclause`: the rover invokes `gurus:gurus` once per mission at INSPECT and the orchestrator picks the panel. |
| **bonsai** | `/bonsai` | | | macOS | Worktree lifecycle manager: create a worktree and put a `cd <worktree> && claude "..."` start command on the clipboard so you can paste it into any terminal pane/tab/app, or prune worktrees with safety checks. Requires macOS (uses `pbcopy`). |
| **clipboard** | `/clipboard` | | | macOS | Copy the core content of the last answer to the clipboard via the `clipboard-copy` helper. `/clipboard slack` for rich text. |
| **dont-do-that** | `/duh`, `/just-a-question` | | ✅ | | Guardrail hooks (one dispatcher, uniform `[dont-do-that/<code>]` messages) that push back on common AI reflexes: shifting blame, stopping prematurely, delegating verification, offering a recipe instead of executing it (`duh` guard), asking for confirmation when none was needed, em-dashes in prose, hallucinated hour/day/week effort estimates (`estimate` guard at Stop catches "een paar uur werk", "halve dag uitzoekwerk", "a few days of work", "binnen een uur", and the "option A is vandaag, B is deze week" comparison frame; calendar, cron, retention, SLA, and past-tense phrasing is filtered so legitimate scheduling and history claims pass; escape with `🧭` for deferred judgment, `🚧` for WIP), and adding code comments to programming-language files (`no-code-comments` guard at PreToolUse uses per-language awk tokenizers to distinguish real comments from strings, allow rules for URL, `allow-comment` escape, pragma allowlist, and shebangs). Plus two user-invocable skills: `/duh` is the operator's one-keystroke correction when Claude proposed an action instead of running it; it tells Claude to execute the proposal from the previous turn (or disambiguate when the turn had multiple proposals). `/just-a-question` is the inverse: half of "this is a question for information, not a request for change", which forbids mutation tools for the rest of the turn so a clarifying question cannot tip into mid-question code edits. See [dont-do-that](packages/dont-do-that/README.md). |
| **drydry** | `/drydry:drydry` | | | | Find and converge parallel paths in any artefact (code in any language, prose, design systems, technical documentation). Methodology guide that disciplines how a duplication audit runs (eight chapters: Type-4 clone framing, verifier-burden LLM pass, allow-list scoping, drift hypothesis, three-bucket triage, two-fates discipline, contrarian second-pass, method-as-artefact) without prescribing what duplication looks like in your codebase. One user-invocable orchestrator `drydry:drydry` with two modes: `quick` (inline "is this duplicate?" check with a runnable verifier-grep, no artefact) and `audit` (full sweep producing a `<scope>-drydry-findings.md` artefact with `## Detection method chosen` and `## Findings`). In audit mode the calling session formulates the six-to-ten item checklist itself by reading the codebase against formulation prompts (canonical-channel bypass, parallel utilities, predicate pairs, framework-seam boilerplate, commit-history clusters, user-facing copy variants, parallel UX surfaces, off-template project-specific patterns, parallel orchestrations above a shared leaf-call); drydry disciplines how the list is used, not what is on it. Six agent-only sub-skills: `sweep` (Sonnet detection pass with verifier-burden discipline; hits without a runnable verifier are dropped), `checklist` (opt-in seed source returning starting-point templates per domain when the operator passes `seed-from <domain>`; the session rewrites the seed against the actual codebase before passing it to sweep), `triage` (three-bucket classification: cheap-and-safe / partial / needs-design with convergence cost per item), `learn` (online research on de-duplication state-of-the-art via parallel WebSearch and WebFetch subagents, enriches the discipline's external vocabulary), `upstream` (cross-toolbox audit against framework offerings: Rails/Devise helpers, SwiftUI/Foundation built-ins, React conventions; uses `inspire` and `ground` patterns to verify the framework actually offers what we suspect), `instructions` (CLAUDE.md audit for instructions that themselves cause DRY violations: two paths prescribed for the same job, or silence on existing helpers causing agent-generated parallel code). See [drydry](packages/drydry/README.md). |
| **export-skill** | `/export-skill` | | | macOS | Export a skill for sharing. Orchestrator that chains five sub-skills, each also user-invocable on its own: `sanitize` (PII + security), `translate` (en/nl), `port` (linux/windows/macos), `package` (zip or single-file md), `share` (clipboard summary + Finder handoff). The `share` sub-skill is macOS-only; the others run anywhere. |
| **eye-of-the-beholder** | `/eye-of-the-beholder`, `/art-director`, `/visual-inspection` | ✅ | | | Three sister skills. `eye-of-the-beholder` catches cramped text, missing margins, and disproportionate spacing in visual layouts (diagnostic, per-change). `art-director` works upstream: captures brand identity, visual language across type / color / form / motion / photography, and design-system architecture (Curtis 3-layer tokens + Frost atomic components) BEFORE CSS exists. `visual-inspection` activates when the user asks to match one element to another along named axes (padding, corner radius, font, color); it forces a reference + result screenshot table comparison before "match" can be claimed. Not for small UI tweaks; for new products, brand refreshes, or first-time DS foundation. |
| **gitgit** | `/gitgit:commit-all-the-things`, `/gitgit:commit-snipe`, `/gitgit:rebase-latest-default`, `/gitgit:merge-to-default`, `/gitgit:push-policy`, `/gitgit:commit-discipline`, `/gitgit:install-hooks`, `/gitgit:run-spec`, `/gitgit:disable-discipline`, `/gitgit:enable-discipline`, `/gitgit:discipline-status`, `/gitgit:disable-git`, `/gitgit:enable-git` | ✅ | ✅ | | Bundle of git-write skills plus a two-layer commit-discipline hook stack. The four day-to-day commands (`commit-all-the-things`, `commit-snipe`, `rebase-latest-default`, `merge-to-default`) cover staging, sniping, rebasing, and landing the current branch on the project default with a github-style `--no-ff` merge. The discipline layer enforces a structured body schema (subject + WHY paragraph + `Slice` / `Tests` / `Red-then-green` / `Visual` trailers parsed via `git interpret-trailers`) on both Claude-driven commits (PreToolUse:Bash dispatcher) and CLI commits (git-native `commit-msg`, `prepare-commit-msg`, `post-commit`, `pre-push` hooks installed per repo via `/gitgit:install-hooks`). Eight `Slice` opt-out tokens (`docs-only`, `config-only`, `migration-only`, `spec-only`, `chore-deps`, `revert`, `merge`, `wip`) plus four logged escape-hatches (`# vsd-skip`, `--no-verify`, `GITGIT_ALLOW_AI_COAUTHOR`, `GITGIT_ALLOW_WIP_PUSH` / `# allow-wip-push`, `GITGIT_TRIVIAL_OK`); `wip` commits are accepted locally but blocked at push time. `Red-then-green: yes` is self-attestation; no cache backs it. `Visual:` is gated by a UI-touch heuristic that scans the staged diff (web-template / styling / iOS storyboard, asset-catalog, and `.swift` files containing SwiftUI / UIKit / AppKit symbols); backend-only commits never see the rule, and false positives are absorbed via `Visual: n/a (reason)`. `/gitgit:run-spec` detects the project's test runner and prints PASS/FAIL without recording evidence. `/gitgit:commit-discipline` is the canonical reference for the schema, error codes, opt-out matrix, and troubleshooting. `/gitgit:disable-discipline` / `/gitgit:enable-discipline` toggle the PreToolUse guards for the current session via a sentinel file in `~/.claude/var/`; `/gitgit:discipline-status` reports the current state. `/gitgit:disable-git [reason]` writes `.git/gitgit-deny` and locks the repo so Claude only allows read-only inspection (status, log, diff, show, blame, rev-parse, branch / tag list); every mutation (commit, checkout, reset, merge, rebase, push, ...) is denied. With `/gitgit:install-hooks` active, the `commit-msg` and `pre-push` git-native hooks honour the same sentinel so direct shell `git commit` / `git push` are also blocked; other shell mutations are not covered CLI-time. `/gitgit:enable-git` lifts the lock. `/gitgit:push-policy` decides whether and when a push fits the current repo: a resolver reads per-repo facts (collaboration, visibility, default-branch protection, push access) and derives one of five modes (`local-only`, `solo-trunk`, `team-trunk`, `pr-flow`, `external`) with distinct push behavior, overridable per repo via git-local `codingAgent.git.*`; `rebase-latest-default` and `merge-to-default` consult it, and the push hooks gate content orthogonally. See [gitgit](packages/gitgit/README.md). |
| **ground** | `/ground` | ✅ | | | Verify Claude's recent output with external sources when you challenge accuracy. |
| **gurus** | `/gurus`, `/gurus:software`, `/gurus:council`, `/gurus:writers` | | | | Opinionated panels that challenge a decision from multiple perspectives. `gurus:software` hosts the eight-persona code review panel (Beck, Fowler, Uncle Bob, DHH, Metz, Evans, Hickey, Ousterhout). `gurus:council` runs Ole Lehmann's five-advisor pattern (pre-mortem, first-principles, opportunity-finder, stranger, action) with anonymised peer-review and chairman synthesis. `gurus:writers` runs a six-writer prose review panel (Didion, Saunders, Rovelli, Watts, Gladwell, Urban) for essays, scripts, manuscripts, and narrative copy; consensus across 4 of 6 yields an action plan of edits, cuts, and rewrites. `/gurus` is an orchestrator that routes between the three panels based on context; it is not itself a review. All voices run on the shared `gurus:sonnet-max` subagent. |
| **how-plugins-work** | `/how-plugins-work`, `/how-plugins-work:test-before-push` | ✅ | | | Living document explaining how Claude Code plugin naming, skill resolution, and the plugin:skill invocation pattern work. The `test-before-push` sub-skill encodes the canonical procedure for pointing a marketplace alias at the local working copy so you can test a plugin change in a fresh Claude session without pushing first. |
| **inspire** | `/inspire` | ✅ | | | Online research workflow for unfamiliar topics, design decisions, and evaluating approaches. |
| **leclause** | `/leclause:whats-new` | | | | Marketplace-wide utilities. Currently ships `whats-new`, a one-stop reader for the post-update CHANGELOG section of any installed leclause plugin. Argument is the plugin name (`/leclause:whats-new gitgit`); without argument, lists every leclause plugin that adopted the broadcast pattern. The reader uses `--force`, so it never advances the per-plugin sentinel under `~/.claude/var/leclause/`. |
| **recap** | `/recap` | | | | Structured status overview of the current session: what we are doing, where we are, what is next. |
| **recursion** | `/recursion` | | | | Nightly workflow-improvement loop. Orchestrator manages schedule, state, focus, reject. Ships with an internal `research` sub-skill that runs parallel friction and external discovery agents, synthesizes findings, and writes atomic improvement plans. |
| **rename-suggestion** | `/rename-suggestion` | | | | Suggest a descriptive session name based on conversation context. Portable; the macOS-only `clipboard-copy` helper is invoked when present, and on other platforms the ghost-text suggestion still works without the clipboard step. |
| **saysay** | `/saysay` | | | macOS | Claude speaks every response aloud. `/saysay off` to exit. |
| **screen-recording** | `/screen-recording` | | | | Automated screen recordings and demo videos of browser-based features. |
| **self-improvement** | `/self-improvement` | | | | Update CLAUDE.md and skills based on feedback. Detects duplication and extracts large sections into skills. |
| **testing-philosophy** | ❌ | ✅ | | | Opinionated testing guide covering TDD workflow, end-to-end behaviour-test conventions (Cucumber/Gherkin and other framework choices), flaky test diagnosis, and test suite health. |
| **whywhy** | `/whywhy [n]` | ✅ | | | Drill N layers deep into a question or goal (default 10), then analyze the chain for a better direction. |

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

All plugins in this marketplace except `testing-philosophy` ship the broadcast pattern. `testing-philosophy` is referenced via the Skill tool only and has no slash command for the broadcast to attach to. The `bin/check-broadcast` helper has a single canonical source at `bin/check-broadcast.mjs` in the repo root; every plugin's `bin/check-broadcast` is a byte-for-byte mirror, kept in sync by `bin/sync-check-broadcast` and policed by the pre-commit hook. Plugin authors do not edit per-plugin copies; they edit the canonical, then run the sync.

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
