#!/bin/sh
cat <<'NOTICE'
saysay@leclause is DEPRECATED and has MOVED to saysay@laicluse-agent-fieldkit.
The skill is unchanged: /saysay turns on speech mode, /saysay off exits.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install saysay@laicluse-agent-fieldkit
  claude plugins uninstall saysay@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
