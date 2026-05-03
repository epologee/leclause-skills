---
name: commit-discipline
user-invocable: true
description: >
  Reference skill for the gitgit commit body schema: subject + WHY
  paragraph + Slice / Tests / Red-then-green trailers parsed via
  git interpret-trailers, with opt-out enum tokens. Read this skill
  when the hook denies a commit and you want the canonical schema,
  examples, escape-hatches, and troubleshooting.
argument-hint: ""
---

# /gitgit:commit-discipline

Canonical reference for the gitgit commit body schema. The PreToolUse:Bash
guard and the git-native hooks (`commit-msg`, `pre-push`) read the same
validator (`hooks/lib/validate-body.sh`); this document describes what
that validator requires, which escape hatches exist, and how to
troubleshoot.

## What

The commit-discipline extension enforces a structured commit body via
two layers: a PreToolUse:Bash guard that intercepts Claude-driven commits,
and git-native hooks (installed via `/gitgit:install-hooks`)
that guard commits made outside of Claude.

The schema consists of three parts: a subject line in imperative
English (50/72 characters), a free-form WHY paragraph that explains
why the change is needed, and a series of trailers in `git interpret-trailers`
format (`Key: Value`, at the bottom of the message). The validator runs
in two layers but shares exactly the same logic, so behavior never
diverges.

Claude Code does not offer a native PreCommit lifecycle event
(https://github.com/anthropics/claude-code/issues/4834, closed not planned),
so the two-layer architecture is final, not provisional.

## The schema

### Subject lines

- Imperative English ("Add handler", not "Added handler" or "Adding handler").
- At most 72 characters; 50 characters is the target for readability in `git log`.
- No period at the end.
- No conventional-commits prefix required (`feat:`, `fix:`), but allowed.
- Automatically skipped for: `Merge ...`, `Revert ...`, `fixup!`, `squash!`, `amend!`.
- Cherry-pick commits: skip runs through both layers. The git-native `commit-msg`
  hook detects cherry-picks because `git cherry-pick -x` adds the phrase
  `(cherry picked from commit <sha>)` to the body. The PreToolUse
  guard detects the same phrase when Claude invokes a `git commit -m '...(cherry
  picked from commit ...)...'` wrapper. A raw `git cherry-pick` from
  the terminal does not pass through PreToolUse, so the layer split does not
  apply there. Without the `-x` flag, the subject does not contain a
  `(cherry picked...)` phrase, which means the anti-copy-paste check can fire
  unjustly if the WHY of the source commit is identical.

### WHY paragraph

- Free-form prose, at least two non-empty lines OR at least 60 characters
  ending in `.`, `!`, or `?`.
- Sits after the subject line, separated by a blank line.
- Anti-copy-paste: the SHA1 of the WHY text must not be identical to that of
  any of the five most recent commits on the current branch.
- Not validated for content (too easy to bullshit), only structurally.

### Required trailers

| Trailer | Value | Required when |
|---------|-------|---------------|
| `Slice` | opt-out token or free-form text (see below) | always |
| `Tests` | comma-separated list of spec paths | when `Slice` is not an opt-out token |
| `Red-then-green` | `yes` or `n/a (reason >= 10 chars)` | when `Slice` is not `docs-only`, `config-only`, `migration-only`, `spec-only`, or `chore-deps` |
| `Visual` | file path or `n/a (reason >= 10 chars)` | when the staged diff touches UI files (see heuristic below) |

**`Slice` rules:** the value is either one of the eight opt-out tokens (see
the next section), or free-form text describing which layers the commit
touches (e.g. `handler + service + spec`, `frontend + backend + migration`).

**`Tests` rules:** every path in the list must exist in the HEAD tree
(`git ls-tree -r HEAD --name-only`) or in the staged diff
(`git diff --cached --name-only`). Supported extensions:
`.rb`, `.py`, `.js`, `.ts`, `.go`, `.sh`, `.bash`, `.feature`, `.tsx`, `.jsx`.
Anchor suffixes (`#method_name`) are stripped for the file existence check.

**`Red-then-green` rules:** value `yes` is self-attestation that the test
was seen in red state; no cache evidence is required or verified.
Value `n/a (reason)` is allowed with a rationale of at least 10 characters.
Bare `n/a` without rationale is rejected.

Structural limitation: the validator checks the presence and format
of `Red-then-green`, not the truth of its content. That is a
deliberate choice: a cache that automatically tracks evidence adds more
complexity than it is worth. Attestation responsibility lies
with the author.

**`Visual` rules:** a path value points to a screenshot or
recording file that must exist in the worktree (`[[ -f "$path" ]]`). The
value `n/a (reason)` is allowed with a rationale of at least 10
characters; bare `n/a` without rationale is rejected. The trailer is only
required when the heuristic below detects UI touches in the
staged diff; backend-only commits do not see the rule and need not
include `Visual`.

**UI-touch heuristic:** the validator scans `git diff --cached --name-only`
and triggers the Visual requirement on any path that matches one of these patterns:

- web template: `.tsx`, `.jsx`, `.vue`, `.svelte`, `.html`, `.htm`,
  `.erb`, `.haml`, `.slim`
- styling: `.css`, `.scss`, `.sass`, `.less`
- iOS storyboard/xib: `.storyboard`, `.xib`
- iOS asset catalog: any path under `*.xcassets/`
- Swift source files: `.swift` whose staged content (`git show :<path>`,
  fallback to worktree) contains one of `import SwiftUI`, `import UIKit`,
  `import AppKit`, `: View {`, `UIView`, `UIViewController`, `NSView`,
  or `NSViewController`

Backend `.swift` files without UI symbols are not covered by the rule.
False positives of the heuristic can be absorbed via
`Visual: n/a (backend rewrite, no UI touched)` or a similar rationale,
analogous to the `Red-then-green: n/a` opt-out. The heuristic does not
consult `Slice` tokens; the trailer fires correctly when a commit with
`chore-deps` slice also bumps a CSS dependency.

**Known false positives.** The extension list deliberately chooses broad
over narrow:

- `.html` also matches backend e-mail templates and HTML fixtures without
  rendering. Escape with `Visual: n/a (e-mail template, no rendered UI)`.
- A `chore-deps` commit that also brings along a generated `.scss` or `.css`
  fires the rule. The Slice token does not explicitly suppress the
  heuristic (a real UI change in a chore-deps commit must
  also get a screenshot). Escape with `Visual: n/a (regenerated by
  package manager, no UI authored)`.
- `.swift` without visible UI symbols falls outside; watch out when the
  staged blob is not available (e.g. partial amend), because then the
  heuristic conservatively classifies the file as non-UI and you must
  opt in yourself via `Visual: <path>` or `Visual: n/a (...)`.

Error codes:

| Code | When |
|------|------|
| `missing-visual` | UI-touch detected but trailer is absent, or trailer is bare `n/a`, or `n/a (reason)` with too short a rationale |
| `visual-path-not-found` | Trailer is not an `n/a` form and the given path does not exist in the worktree |
| `visual-rationale-defers` | The `n/a (rationale)` text uses deferral language (`later`, `follow-up`, `next iteration`, `to be captured`, `will capture`, `coming next`, `post-merge`, `saved for later`) that promises a screenshot at a future event. The trailer cannot validate that promise; either supply `Visual: <path>` now or rewrite the rationale to describe why a screenshot has no meaning for this change (extract-only refactor, accessibility metadata, debug-only surface, copy-only). |
| `visual-rationale-vague` | The `n/a (rationale)` text does not name a recognized non-applicable category. The closed enum is: `extract-only`, `accessibility-only`, `accessibility metadata`, `debug-only`, `spec-only`, `test-only`, `copy-only`, `copy change`, `metadata-only`, `no behaviour change`, `no visual change`, `no ui change`, `byte-identical`, `render unchanged`, `pixel-identical`, `backend rewrite`, `backend only`, `no ui touched`, `sound-only`, `audio-only`, `log-only`, `telemetry-only`. The rationale must contain at least one of these tokens (case-insensitive) so the claim "no screenshot has meaning here" is classified rather than narrated. |
| `review-pass-batch` | The WHY block names a review pass (`pride pass`, `end-user pass`, `technical pass`, `review pass`, `review findings`, `pride contrarian`, `review contrarian`) and lists two or more findings as bullets. Review-pass commits should land one finding per commit so each fate (fix, reject-with-evidence) is its own reviewable unit; rewrite the WHY in prose for one finding and split the others into separate commits, or remove the review-pass keyword if this is not a review-pass commit. |

### Optional trailers

| Trailer | Value |
|---------|-------|
| `Resolves` | URL to issue, Sentry, incident; or `none` |
| `Cucumber` | `applicable` (and used), or `n/a (reason)` |
| `Co-authored-by` | allowed provided it is not an `@anthropic.com` address (see escape hatches) |

Trailers are parsed via `git interpret-trailers --parse`. Order
within the trailer block does not matter.

### Subject conjunction

The subject must not join two changes with a conjunction. The format
guard rejects subjects containing ` and `, ` + ` (space-plus-space),
or ` & ` because they signal that the author bundled multiple
changes behind one subject. Split into separate commits, or rewrite
the subject as one cohesive change. When the joined form is
intentional (e.g. an atomic refactor that genuinely couples two
verbs), set `GITGIT_ALLOW_CONJUNCTION=1` in the shell for the single
commit, or add `# allow-conjunction: <reason>` to the body.

## Opt-out enum

If `Slice` is one of these eight tokens, relaxed rules apply:

| Token | When to use |
|-------|-------------|
| `docs-only` | Only changes in documentation (`.md`, `.txt`, `.rst`, README) |
| `config-only` | Only changes in configuration files without behavior change |
| `migration-only` | Only database migrations without an associated handler/spec change |
| `spec-only` | Commit contains only spec/test files (the diff is itself the red evidence) |
| `chore-deps` | Dependency bumps, lockfile updates, build system tweaks |
| `revert` | Full revert of an earlier commit |
| `merge` | Merge commits (typically created automatically) |
| `wip` | Work-in-progress commit on a feature branch; **blocked at push** |

For `docs-only`, `config-only`, `migration-only`, `spec-only`, and `chore-deps`
the `Red-then-green` requirement also drops. Rationale: migrations have no
meaningful red-then-green sequence; spec-only commits are themselves the red
phase (the spec existed before the implementation). For all eight, the
`Tests` requirement drops.

`wip` commits are accepted at commit time but blocked by the
pre-push gate. You cannot accidentally send a wip commit to remote.

## Rotation reminders

In addition to the structural subject and body checks, the
PreToolUse:Bash guard `commit-subject.sh` rotates one thematic
reminder from the table below on every commit. Acknowledge with
`# ack-rule<N>:<password>` as a trailing shell comment behind the
git command. The password is a mnemonic that is referentially tied
to the rule, so looking it up forces one exposure per cycle.

| Rule | Password | Rule |
|------|----------|------|
| 1 | `gedrag` | Subject = new behavior/capability, no git action ("Fix/Add/..."). |
| 2 | `effect` | Subject says WHAT the system does, not the WHY trigger ("Address feedback"). |
| 4 | `essentie` | Body only when needed: 2-4 sentences why. |
| 5 | `dubbelop` | No file listings or class inventory; the diff already shows files. |
| 6 | `proza` | No bullet dumps or meta-narrative ("reviewer asked", "tests failed"). |
| 7 | `atoom` | Logically independent changes = separate commits; test + impl of 1 feature = 1 atomic commit. |
| 8 | `inferno` | Never commit broken code with "fix in next commit". |
| 9 | `solist` | No Co-Authored-By from AI tooling unless asked. |
| 10 | `incognito` | No 'Generated with Claude Code' footer. |
| 11 | `loep` | Review the staged diff before commit; tool output is not evidence. |
| 12 | `bewijsstuk` | Commit check is evidence (test ran, endpoint hit), not gut feel. |
| 13 | `kralen` | Never squash merge; preserve history. |
| 14 | `voorwaarts` | Amend is forbidden unless stripping unpushed secrets/PII; use a new commit. |

Rule 3 (subject length 50/72) is enforced structurally by
`commit-format.sh` and is not in the rotation. Rules 1 and 2 only
land on you after a real violation in the subject; rules 4-14 rotate in
slot order, one per commit. State lives in
`~/.claude/var/gitgit-commit-rule-state` and shifts after every
successful ack. The canonical mnemonic table that the hook validates
against is in `packages/gitgit/hooks/lib/rotation-rules.sh`.

## Examples

### Example 1: feature commit with handler + service + spec + Red-then-green

```
Drop invalid meter reading on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts and stops in analytics.
This change keeps the transaction event but discards just the bad
reading, restoring the visibility we lost.

Tests: spec/services/session_spec.rb#start_event_with_bad_reading,
       spec/services/session_spec.rb#stop_event_with_bad_reading
Slice: handler + service + spec
Red-then-green: yes
Resolves: https://example.org/backlog/issues/1234
```

### Example 2: docs-only opt-out with minimal trailers

```
Update install instructions for Windows consumers

The symlink-free layout means Windows users need cp -f instead of
ln -s. The previous instructions silently created a text file.

Slice: docs-only
```

(No `Tests` or `Red-then-green` required for `docs-only`.)

### Example 3: chore-deps version bump

```
Bump bundler to 2.5.18

Security patch for CVE-2026-XXXX. No behavior change expected;
suite still loads without modification.

Tests: spec/spec_helper.rb
Slice: chore-deps
Red-then-green: n/a (no behavior change)
```

### Example 4: migration-only opt-out

```
Add NOT NULL constraint to sessions.user_id

The column was introduced in a prior migration without the constraint.
A backfill confirmed no null rows exist in production before this runs.

Slice: migration-only
```

(No `Tests` or `Red-then-green` required for `migration-only`.)

### Example 5: spec-only opt-out

```
Add failing specs for enrollment race-condition fix

Tests written first to drive the implementation. The handler does not
exist yet; these specs are the red phase.

Slice: spec-only
```

(No `Tests` or `Red-then-green` required for `spec-only`.)

### Example 6: UI touch with `Visual:` trailer

```
Render onboarding banner above tab strip

The banner replaces the static placeholder we shipped last week
and now hosts the IAP teaser for unconfigured users.

Tests: spec/views/onboarding_view_spec.rb
Slice: frontend layer
Red-then-green: yes
Visual: doc/screenshots/onboarding-banner.png
```

`Visual:` may also be `n/a (reason)` for false positives of the
heuristic or for commits where UI files are changed but
without a pixel effect (e.g. a reorganized component without render
change):

```
Extract OnboardingBanner into its own file

Pure organizational split; render output is byte-identical to the
previous version. No screenshot needed.

Tests: spec/views/onboarding_view_spec.rb
Slice: frontend layer
Red-then-green: yes
Visual: n/a (extract only, render output unchanged)
```

### Example 7: wip commit (and the pre-push gate that holds it back)

```
Sketch enrollment race-condition fix

Half-baked: the locking strategy is not settled yet. Saving state
before context switch.

Slice: wip
```

This commit goes through locally. A `git push` with this commit in the
range is blocked by the pre-push gate with:

```
wip-gate: commit <sha> has Slice: wip in push range
Set GITGIT_ALLOW_WIP_PUSH=1 or add '# allow-wip-push' to bypass.
```

## Escape hatches

### `# vsd-skip: <reason>` in the commit body

Add a comment line to the body (starts with `#`):

```
Fix typo in error message

# vsd-skip: trivial one-char fix, full schema not warranted
```

The validator reads the comment lines (before stripping) and
logs the reason to `~/.claude/var/gitgit-skips.log`. The commit
goes through. The reason may not be empty.

**`vsd-skip` does not work on UI-touched commits.** When the UI-touch
heuristic fires (SwiftUI/UIKit/AppKit, `.tsx`/`.jsx`/`.vue`/`.svelte`,
`.html`/`.css`/`.scss`, `.erb`/`.haml`/`.slim`, `.storyboard`/`.xib`,
`.xcassets/`), the magic comment is rejected with
`vsd-skip-ui-touch`. Use `Visual: <path>` (screenshot in the repo)
or `Visual: n/a (rationale)` instead. The opt-out remains available for
backend, spec, and migration commits.

### `GITGIT_AUTONOMOUS=1`

Stricter variant for unattended commits (rover, autonomous-loop). Set
the env var before `git commit` runs. Two extra rules:

1. `# vsd-skip` is rejected unconditionally with
   `vsd-skip-autonomous`.
2. `Visual: n/a (rationale)` is rejected on UI-touched commits with
   `visual-na-autonomous`. Only `Visual: <path>` remains allowed; the
   path must also exist (existing `visual-path-not-found` rule).

Backend-only commits are not affected; `Visual: n/a (rationale)` remains
valid there.

**Recommended default for AI-driven sessions.** Treat agent-authored
sessions (Claude Code, Cursor, Aider, codex-rs, OpenCode) as autonomous
by default and export `GITGIT_AUTONOMOUS=1` in the shell-init so every
commit the agent makes runs under the stricter ruleset. The agent
otherwise has every incentive to take the n/a-with-rationale escape on
UI-touched commits ("evidence lands later") and the rationales pass
the format check while never resolving into actual screenshots. The
operator can still authorise an interactive opt-out for a specific
commit via `unset GITGIT_AUTONOMOUS` in that single shell.

### `--no-verify`

`git commit --no-verify` skips all git-native hooks. The PreToolUse:Bash
guard does not intercept this pattern (the flag is in the command string, not a
separate hook). The post-commit hook logs `--no-verify` usage to
`~/.claude/var/gitgit-no-verify.log` for after-the-fact auditing.

**Race window limitation:** the detector uses a trace window of 30
seconds. Concurrent commits in another shell can refresh the trace
and mask a bypass in this shell. Long test runs (>30s between starting
commit-msg and post-commit firing) can produce false positives.
The audit log is best-effort, not authoritative.

### `GITGIT_ALLOW_AI_COAUTHOR=1`

The `commit-trailers.sh` guard blocks `Co-Authored-By:` trailers with an
`@anthropic.com` e-mail address. Set `GITGIT_ALLOW_AI_COAUTHOR=1` to
bypass that specific block (e.g. for explicit attribution requirements).

### `GITGIT_ALLOW_WIP_PUSH=1` or `# allow-wip-push`

Bypasses the pre-push wip-gate for the current push. Both forms are logged
to `~/.claude/var/gitgit-wip-pushes.log`. Use the magic-comment form
when you want to document the bypass in the command itself without
exporting an environment variable.

**Asymmetry:** the `# allow-wip-push` magic comment only works when
Claude executes the push (the PreToolUse:Bash guard reads the bash command string).
For pushes you run yourself in a terminal, only
`GITGIT_ALLOW_WIP_PUSH=1` works; the git-native pre-push hook does not
read the command string.

### `GITGIT_TRIVIAL_OK=1`

Set automatically by the PreToolUse:Bash guard when the staged diff has
at most 1 file and at most 5 insertions. Can also be exported manually
to skip body validation for a specific trivial commit.
Not persistent; applies only to the next commit.

**Limitation:** manual export of `GITGIT_TRIVIAL_OK=1` only applies to the
PreToolUse:Bash layer. The git-native commit-msg hook re-derives the
trivial flag from the staged diff on every run; an externally exported
value does not bypass that hook. For trivial-but-larger commits at
the git-native layer, use the `# vsd-skip: <reason>` magic comment instead of the
environment variable.

## Troubleshooting

**"The hook blocks my commit with missing-tests; how do I fix it?"**

The `Tests:` trailer is missing or contains no valid path. Add a
`Tests:` line with the paths of the specs you ran, e.g.:

```
Tests: spec/services/enrollment_spec.rb, spec/models/device_spec.rb
```

The paths are checked against the HEAD tree and the staged diff. Make
sure the files actually exist in the project. If there are no tests (e.g.
pure config change), use a fitting opt-out token:
`Slice: config-only`.

**"My body is clear enough but the hook says why-too-short"**

The WHY paragraph is too compact. The validator requires at least two
non-empty lines OR at least 60 characters ending in `.`, `!`, or `?`. A
single-line summary of 30 characters does not qualify. Break the
sentence into two lines or write a more complete explanation.

**"I get duplicate-why; I wrote my body myself"**

The SHA1 of your WHY text (after whitespace normalization) matches exactly
that of one of the five most recent commits on the current branch. This
points to copy-paste from an earlier commit message. Rewrite the WHY for
this specific commit; even small textual deviations are enough.

**"push blocked by wip-gate but the wip commit was already amended"**

If you have amended a `Slice: wip` commit into a normal schema-compliant
commit, the wip-gate sometimes runs over a stale reflog entry. Check with
`git log --oneline` whether there is still a `Slice: wip` commit in the push range.
If there is none left but the gate still blocks, set `GITGIT_ALLOW_WIP_PUSH=1`
for the push and report the edge case.

## Session-level kill-switch

When you want to temporarily turn off the gitgit guards without disabling
the plugin globally, use `/gitgit:disable-discipline`. That writes a sentinel file in
`~/.claude/var/` with your session id; the dispatcher exits early on every
`git commit` or `git push`. Re-enable with `/gitgit:enable-discipline`. Status check with
`/gitgit:discipline-status`. The skills are user-invocable; Claude does not
invoke them itself to bypass the discipline.

## Architecture

The enforcement consists of two parallel layers that call the same
`hooks/lib/validate-body.sh`:

```
git commit (via Claude Code)
    |
    v
PreToolUse:Bash dispatcher (hooks/dispatch.sh)
    |-- git-dash-c.sh       (blocks git -C <dir>)
    |-- commit-format.sh    (editor-mode detection)
    |-- commit-subject.sh   (50/72 subject rules)
    |-- commit-body.sh      (body schema, trivial check)
    |-- commit-trailers.sh  (Co-Authored-By @anthropic.com)
    |-- push-wip-gate.sh    (wip commits on git push)
    |
    +-> validate-body.sh (shared library)
           |-- layer-classify.sh
           |-- example-synth.sh
           +-- wip-gate.sh

git commit (outside Claude, via CLI or IDE)
    |
    v
git-native hooks (installed via /gitgit:install-hooks)
    |-- commit-msg          -> validate-body.sh (same lib)
    |-- prepare-commit-msg  -> layer-classify.sh (template-fill)
    |-- post-commit         (logs --no-verify usage)
    +-- pre-push            -> wip-gate.sh
```

The git-native hooks live in
`packages/gitgit/skills/commit-discipline/git-hooks/` and are copied
(not symlinked) by `install-hooks`.

## Migration leftovers

The commit-subject and commit-format guards have moved from `dont-do-that`
to `gitgit/hooks/guards/` (slice 2). The user-level git hooks
(`block-coauthored-trailer.sh`, `warn-untested-commits.sh`,
`block-git-dash-c.sh`) have been absorbed into `gitgit/hooks/guards/` (slice 5).
`~/.claude/hooks/` no longer contains any git-touching hooks after the migration.

The audit script lives in the plugin under `bin/audit-no-body-commits`. Use it
as follows to always run it against the active plugin version:

```bash
GITGIT=$(jq -r '.plugins["gitgit@leclause"][0].installPath' \
  ~/.claude/plugins/installed_plugins.json)
python3 "$GITGIT/bin/audit-no-body-commits"
python3 "$GITGIT/bin/audit-no-body-commits" --branch main --since 2026-04-01
python3 "$GITGIT/bin/audit-no-body-commits" --exclude-trivial
```
