#!/bin/sh
cat <<'NOTICE'
dont-do-that@leclause is DEPRECATED and has moved to dont-do-that@laicluse-agent-fieldkit.
This plugin no longer ships any skills, guards, or hook dispatcher; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install dont-do-that@laicluse-agent-fieldkit
  claude plugins uninstall dont-do-that@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
