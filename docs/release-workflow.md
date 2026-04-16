# Release workflow: keeping the marketplace Windows-installable

## The short version

Two branches, one source of truth, no thinking required during normal work.

- **`main`** is the working branch. Plugins share skills via relative symlinks (`packages/<plugin>/skills/<skill>` → `../../../skills/<skill>`). macOS and Linux consumers install from `main` and everything works.
- **`release`** is the Windows-installable snapshot. Every symlink is replaced by its target content, so Git for Windows does not turn anything into text files on clone. Windows consumers install from `@release`.

`bin/marketplace-release` builds the `release` branch from the current state of `main`. A GitHub Action (`.github/workflows/release-branch.yml`) runs it automatically on every push to `main`, so Windows consumers catch up without any manual step. Run the script by hand only when you want to publish before CI runs or when debugging.

## When to run

The GitHub Action covers the normal path: any push to `main` triggers `bin/marketplace-release --write`. Authoring flow becomes: commit on main, push, Windows consumers get a fresh release automatically.

Run the script by hand only in these cases:

- You want to publish a release without going through `main` (for example, testing a staging branch locally against the materialised artefact).
- The Action failed and you want to reproduce the failure locally.
- You are debugging the pipeline itself.

## How to run

From a clean working tree on `main`:

```bash
bin/marketplace-release           # Dry-run: build staging, show summary
bin/marketplace-release --write   # Build staging, force-push origin/release
```

The script refuses to run from any branch other than `main`, or with uncommitted changes in the working tree. That is deliberate; `release` is meant to reflect the shippable state of `main` and nothing else.

Staging lands in a fresh temp directory under `/tmp/leclause-release-build.*` (created via `mktemp -d`) and is cleaned up on exit. Each run gets an isolated dir so concurrent runs do not collide.

## What happens under the hood

`bin/marketplace-release`:

1. Verifies you are on `main` with a clean working tree, bails otherwise.
2. `rsync -aL` copies the repo into `/tmp/leclause-release-build/`. The `-L` flag dereferences symlinks, so every entry in the staging tree is a real file or directory. Excludes `.git`, `.autonomous`, `node_modules`, and `*.lock`.
3. Sanity-checks that zero symlinks remain in the staging tree. If any do, it bails loudly with the list.
4. In `--write` mode, inside the staging tree: `git init -b release`, add everything, commit with a message tagging the source SHA from `main`, then force-push to `origin/release`.

The force-push is intentional. The `release` branch is a regenerated artefact, not an accumulation of commits. Each release is a fresh root commit (no parent) force-pushed over the previous release's root commit. Consumers with a local checkout of `release` see diverged history on each push, which is fine because nobody develops there.

## Why this beats the alternatives

Other paths exist; none of them bring plugins to every Windows consumer without asking the consumer to do something. They were considered and rejected in [`docs/windows-compat-investigation.md`](windows-compat-investigation.md).

## How the tooling keeps you honest

You should not have to remember this workflow every time you author a plugin. Two guards enforce it mechanically:

- **`hooks/pre-commit` blocks new consumer-facing shell scripts.** Any file under `packages/<plugin>/bin/` with a bash, sh, or zsh shebang is rejected at commit time. Port to Node or Python first. Shell on Windows via WSL/Git Bash is not a guarantee across all Claude Code setups; native PowerShell exists.
- **`bin/marketplace-release` is a pure build step.** It does not require coordination with `plugin-versions` or `marketplace.json`; it just materialises whatever main currently contains. Adding a new plugin on main and running the release script is the entire publish flow.

If you add a plugin that has a consumer-facing requirement the guards do not cover (new file type, new install-time assumption, new runtime dependency), add that check here so it becomes mechanical.

## The part that still needs a Windows machine

Local testing on macOS validates that the release pipeline produces a symlink-free artefact and that `claude plugins install` consumes it cleanly. That is 99% confidence. The 1% gap: Claude Code's install pipeline on Windows may itself create absolute symlinks in the plugin cache that require Developer Mode or admin to create.

The first real Windows install is the missing test. Hand it to someone with a recent Windows machine. Ask them to:

1. `claude plugins marketplace add <owner>/<repo>@release`
2. `claude plugins install autonomous@leclause`
3. Restart Claude Code
4. Type `/autonomous:help` and confirm the ASCII rover briefing appears

If step 4 works, the pipeline is end-to-end validated. If it does not, the failure mode tells us whether laag 2 (cache symlink creation) is actually a problem or not, and we iterate from there.

## Related

- [`docs/windows-compat-investigation.md`](windows-compat-investigation.md): the full problem analysis and why materialise-at-release is the approach.
- `bin/marketplace-release`: the script itself, under 100 lines of shell, commented.
- `hooks/pre-commit`: the mechanical guard against new non-portable scripts.
- `skills/how-plugins-work/SKILL.md`: documents symlink handling and cross-platform materialisation in general.
