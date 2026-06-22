#!/bin/sh
cat <<'NOTICE'
bonsai@leclause is DEPRECATED and has MOVED to bonsai@laicluse-agent-tools.
The successor is a cross-platform CLI: create, setup, and prune (teardown)
worktrees. The clipboard / start-command behaviour and the macOS-only
requirement are gone; bonsai now emits facts and launches nothing.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-tools
  claude plugins install bonsai@laicluse-agent-tools
  claude plugins uninstall bonsai@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
