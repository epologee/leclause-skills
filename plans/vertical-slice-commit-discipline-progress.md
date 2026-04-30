# Vertical Slice Commit Discipline - Progress Logbook

This logbook was created retroactively in the fix-commit for the
comprehensive inspection pass. The per-slice entries below are
reconstructed from the branch history; they are not true per-commit
entries as originally intended by the plan. The plan called for this
file to be added incrementally, but it was omitted during the slice
commits. This entry records that decision explicitly.

Branch: `gitgit-commit-body-hooks`
Base: commit before `f3cdbe2`

---

## Slice 1: Skeleton + shared validator

**SHA:** `f3cdbe2`
**Subject:** Introduce gitgit hook skeleton with shared body validator

Files added:
- `packages/gitgit/hooks/dispatch.sh`
- `packages/gitgit/hooks/lib/validate-body.sh`
- `packages/gitgit/hooks/lib/common.sh`
- `packages/gitgit/hooks/lib/layer-classify.sh`
- `packages/gitgit/hooks/lib/example-synth.sh`
- Initial BATS suite under `test/validate-body/`

BATS count at end of slice: ~40 cases
Decisions: validate-body exits 0/1/2 (ok/violation/skip); skip-pattern
classifier extracted as a named function for reuse from git-native hooks.

---

## Slice 2: Migrate commit-format and commit-subject

**SHA:** `5552860`
**Subject:** Migrate commit-rule and commit-format to gitgit

Files added/modified:
- `packages/gitgit/hooks/guards/commit-format.sh`
- `packages/gitgit/hooks/guards/commit-subject.sh`
- Migration parity BATS: `test/migration/parity.bats`
- `test/migrated-hooks/`

BATS count at end of slice: ~80 cases
Decisions: commit-subject rotation state moved from `dont-do-that` path
to `~/.claude/var/gitgit-commit-rule-state` with one-shot migration on
first run.

---

## Slice 3: Shadow-mode commit-body guard

**SHA:** `eeefc84`
**Subject:** Wire commit-body shadow-mode into gitgit

Files added:
- `packages/gitgit/hooks/guards/commit-body.sh` (shadow-mode)
- `test/shadow-mode/`

BATS count at end of slice: ~110 cases
Decisions: shadow-mode logs violations but does not block. Repo-gate
limited logging to the leclause-skills repo only in this slice.

---

## Slice 4: Block-mode commit-body guard

**SHA:** `f7ab722`
**Subject:** Block commits missing the body schema in gitgit

Files modified:
- `packages/gitgit/hooks/guards/commit-body.sh` (shadow -> block mode)
- `test/block-mode/`

BATS count at end of slice: ~130 cases
Decisions: repo-gate removed; block-mode is universal across all repos.
Trivial-commit threshold (<=1 file AND <=5 insertions) bypasses body
requirement automatically.

---

## Slice 5: Absorb user-level git hooks

**SHA:** `9053f90`
**Subject:** Absorb user-level git hooks into gitgit guards

Files added:
- `packages/gitgit/hooks/guards/commit-trailers.sh`
- `packages/gitgit/hooks/guards/git-dash-c.sh`
- `test/migrated-hooks/commit-trailers.bats`
- `test/migrated-hooks/git-dash-c.bats`

BATS count at end of slice: ~145 cases
Decisions: `block-coauthored-trailer.sh` and `block-git-dash-c.sh`
absorbed as named guards; `warn-untested-commits.sh` retired (superseded
by body-schema enforcement).

---

## Slice 6: Git-native commit-msg hook via install-hooks skill

**SHA:** `7bc45d9`
**Subject:** Wire git-native commit-msg via install-hooks skill

Files added:
- `packages/gitgit/skills/install-hooks/` (skill + lib/install.sh)
- `packages/gitgit/skills/commit-discipline/git-hooks/commit-msg`
- `packages/gitgit/skills/commit-discipline/git-hooks/post-commit`
- `test/install-hooks/`

BATS count at end of slice: ~165 cases
Decisions: `__PLUGIN_INSTALL_PATH__` placeholder baked at install time
via sed substitution; post-commit uses 30s trace window for --no-verify
detection rather than per-PID sentinels.

---

## Slice 7: Pre-push wip-gate

**SHA:** `35b4812`
**Subject:** Block wip commits at push time via gitgit gate

Files added:
- `packages/gitgit/hooks/guards/push-wip-gate.sh`
- `packages/gitgit/hooks/lib/wip-gate.sh`
- `packages/gitgit/skills/commit-discipline/git-hooks/pre-push`
- `packages/gitgit/bin/audit-no-body-commits`
- `test/wip-gate/`

BATS count at end of slice: ~185 cases
Decisions: two bypass paths (env-var + magic-comment), both logged to
`~/.claude/var/gitgit-wip-pushes.log`. Audit script in Python for
cross-platform portability.

---

## Slice 8: prepare-commit-msg template fill

**SHA:** `7de884d`
**Subject:** Pre-fill commit messages from staged-diff layers

Files added:
- `packages/gitgit/skills/commit-discipline/git-hooks/prepare-commit-msg`
- `test/template-fill/`

BATS count at end of slice: ~200 cases
Decisions: template emits comment-only trailers in this slice; Fix 9 of
the comprehensive inspection later corrects this to real trailer lines
with placeholder values.

---

## Slice 9: Test-runner cache

**SHA:** `9d8036c`
**Subject:** Cache test-runner evidence for body-schema checks

Files added:
- `packages/gitgit/hooks/lib/test-cache.sh`
- `packages/gitgit/skills/run-spec/`
- `packages/gitgit/skills/saw-red/`
- `test/test-cache/`

BATS count at end of slice: 207 cases
Decisions: cache is opt-in via `GITGIT_TEST_CACHE_REQUIRED=1`; default
off for backwards compatibility. Cache window 6 hours; per-tree-SHA
entries allow tracking across branch switches.

---

## Slice 10: Reference documentation

**SHA:** `609d4d3`
**Subject:** Document gitgit commit-discipline as user reference

Files added:
- `packages/gitgit/skills/commit-discipline/SKILL.md`
- `packages/gitgit/README.md` updates
- `packages/gitgit/skills/commit-discipline/audit-shadow-log`

BATS count at end of slice: 207 cases (no new tests; doc-only slice)

---

## Comprehensive fix-commit (post-inspection)

**SHA:** to be assigned (this logbook created in the fix-commit)

Fixes applied per three-pass inspection (pride, end-user, technical):
18 items across CRITICAL / HIGH / MEDIUM / LOW categories. Key changes:

- Fix 1 (CRITICAL): redirect-order bug in stderr capture corrected in
  `commit-body.sh` and `git-hooks/commit-msg` (2>&1 >/dev/null -> 2>&1).
- Fix 2 (HIGH): `spec-only` added to OPT_OUT_ENUM; `migration-only` and
  `spec-only` added to RTG_EXEMPT in `validate-body.sh`.
- Fix 3 (HIGH): free-text Slice minimum 10-char length rule added.
- Fix 4 (HIGH): cherry-pick skip pattern added to classifier and
  body-content check in `validate-body.sh`.
- Fix 5 (MEDIUM): `commit-format.sh` and `commit-subject.sh` now call
  `dd_extract_commit_message` instead of duplicating the parser.
- Fix 6 (MEDIUM): `install-hooks/SKILL.md` updated to describe all 4
  hooks including `prepare-commit-msg` and `pre-push`.
- Fix 7 (MEDIUM): audit script path clarified in README.md and SKILL.md
  via `installed_plugins.json` resolution pattern.
- Fix 8 (MEDIUM): `%ae` (author email) dropped from post-commit log format.
- Fix 9 (MEDIUM): `prepare-commit-msg` now emits real trailer lines with
  `<placeholder>` values instead of comment-only trailers.
- Fix 10 (MEDIUM): cross-layer BATS suite added under `test/cross-layer/`.
- Fix 11 (LOW): post-update procedure section added to install-hooks/SKILL.md.
- Fix 12 (LOW): unreachable "unknown" mechanism in push-wip-gate replaced
  with BUG assertion.
- Fix 13 (LOW): `|` sanitised in subject and branch before shadow-log write.
- Fix 14 (LOW): --no-verify trace race-window documented in SKILL.md.
- Fix 15 (LOW): GITGIT_TRIVIAL_OK manual-export asymmetry documented.
- Fix 16 (LOW): wip-push magic-comment asymmetry documented in SKILL.md
  and README.md.
- Fix 17 (LOW): this logbook created (recovery, not per-commit).
- Fix 18 (LOW): anti-copy-paste HEAD-linear comparison documented in comment.

BATS count after fix-commit: ~230+ cases (cross-layer adds ~9, new
slice/rtg coverage adds ~8, cherry-pick adds 2, length-check adds 3,
prepare-commit-msg shape adds 2).
