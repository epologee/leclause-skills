#!/bin/sh
cat <<'NOTICE'
clipboard@leclause is DEPRECATED and has MOVED to clipboard@laicluse-agent-fieldkit.
The commands are unchanged: /clipboard and /clipboard slack.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install clipboard@laicluse-agent-fieldkit
  claude plugins uninstall clipboard@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
