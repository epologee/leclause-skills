#!/bin/sh
cat <<'NOTICE'
how-plugins-work@leclause is DEPRECATED and has moved to how-plugins-work@laicluse-agent-fieldkit.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install how-plugins-work@laicluse-agent-fieldkit
  claude plugins uninstall how-plugins-work@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
