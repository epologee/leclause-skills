#!/bin/sh
cat <<'NOTICE'
intervision@leclause is DEPRECATED and has moved to intervision@laicluse-agent-tools.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-tools
  claude plugins install intervision@laicluse-agent-tools
  claude plugins uninstall intervision@leclause

Full migration: /leclause:whats-new
NOTICE
