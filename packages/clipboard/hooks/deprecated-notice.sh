#!/bin/sh
cat <<'NOTICE'
clipboard@leclause is DEPRECATED and has MOVED to clipboard@laicluse-agent-tools.
The commands are unchanged: /clipboard and /clipboard slack.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-tools
  claude plugins install clipboard@laicluse-agent-tools
  claude plugins uninstall clipboard@leclause

Full migration guide: https://github.com/epologee/laicluse-agent-tools/blob/main/docs/migration.md
NOTICE
