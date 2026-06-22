#!/bin/sh
cat <<'NOTICE'
autonomous@leclause is DEPRECATED and has SPLIT into two plugins on laicluse-agent-fieldkit:
  rover@laicluse-agent-fieldkit       the mission framework (/autonomous:rover is now /rover:rover,
                                   same rename for prepare, decide, pride, trim, verify, stop, rover-help)
  autonomous@laicluse-agent-fieldkit  only the stay-alive layer (keepalive, cron, wake); rover pulls it in itself
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install rover@laicluse-agent-fieldkit
  claude plugins install autonomous@laicluse-agent-fieldkit
  claude plugins uninstall autonomous@leclause

Existing .autonomous/ loop files stay readable; the successor rover wakes them unchanged.
Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
