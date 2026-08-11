#!/bin/sh
cat <<'NOTICE'
gurus@leclause is DEPRECATED and has MOVED to gurus@laicluse-agent-fieldkit.
The four skills keep the same names: gurus:software, gurus:council, gurus:writers, and gurus:gurus.
This plugin no longer ships skills or subagents; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install gurus@laicluse-agent-fieldkit
  claude plugins uninstall gurus@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
