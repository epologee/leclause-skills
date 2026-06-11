#!/bin/sh
cat <<'NOTICE'
how-plugins-work@leclause is DEPRECATED and has moved to how-plugins-work@laicluse-agent-tools.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-tools
  claude plugins install how-plugins-work@laicluse-agent-tools
  claude plugins uninstall how-plugins-work@leclause

Full migration guide: https://github.com/epologee/laicluse-agent-tools/blob/main/docs/migration.md
NOTICE
