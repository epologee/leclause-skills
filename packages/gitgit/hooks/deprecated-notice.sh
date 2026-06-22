#!/bin/sh
cat <<'NOTICE'
gitgit@leclause is DEPRECATED and has moved to git-discipline@laicluse-agent-fieldkit.
This plugin no longer ships any skills or commit hooks; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install git-discipline@laicluse-agent-fieldkit
  claude plugins uninstall gitgit@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
