#!/bin/sh
cat <<'NOTICE'
anger-management@leclause is DEPRECATED and has moved to anger-management@laicluse-agent-tools.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-tools
  claude plugins install anger-management@laicluse-agent-tools
  claude plugins uninstall anger-management@leclause

Your existing friction captures migrate automatically on the next capture or repair.
Full migration: /leclause:whats-new
NOTICE
