#!/bin/sh
cat <<'NOTICE'
gitgit@leclause is DEPRECATED and has moved to git-discipline@laicluse-agent-tools.
This plugin no longer ships any skills or commit hooks; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-tools
  claude plugins install git-discipline@laicluse-agent-tools
  claude plugins uninstall gitgit@leclause

Full migration guide: https://github.com/epologee/laicluse-agent-tools/blob/main/docs/migration.md
NOTICE
