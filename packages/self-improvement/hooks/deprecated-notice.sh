#!/bin/sh
cat <<'NOTICE'
self-improvement@leclause is DEPRECATED and has moved to self-improvement@laicluse-agent-fieldkit.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install self-improvement@laicluse-agent-fieldkit
  claude plugins uninstall self-improvement@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
