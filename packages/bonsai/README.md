# bonsai

Worktree lifecycle manager. Two modes: create a new worktree with a branch and launch a Claude session in a fresh iTerm2 pane, or prune existing worktrees with safety checks that prevent work loss.

Auto-triggers when a `.bonsai` file is spotted in a repository (via git status, ls, or file exploration) to verify gitignore setup.

## Commands

### `/bonsai new <branch> [prompt]`

Creates a worktree, switches to a new branch, opens an iTerm2 pane, and starts a Claude session there. Optional prompt text seeds the new session.

### `/bonsai prune`

Lists worktrees and offers cleanup based on context: merged branches, abandoned work, stale worktrees. Refuses to drop worktrees with uncommitted changes or unpushed commits unless overridden.

## Requirements

macOS with iTerm2. The new-pane behavior uses `osascript` to drive iTerm2, which is macOS-only. `/bonsai prune` works anywhere git runs.

If you wrap `claude` (alias, custom flags, model pinning), expose your wrapper via the `CLAUDE_CLI` env var in your shell rc:

```bash
export CLAUDE_CLI=my-wrapper
```

Bonsai falls back to `claude` when the var is not set.

## Installation

```bash
/plugin install bonsai@leclause
```
