#!/bin/sh
cat <<'NOTICE'
eye-of-the-beholder@leclause is DEPRECATED and has MOVED to eye-of-the-beholder@laicluse-agent-fieldkit.
The skills are unchanged: eye-of-the-beholder, art-director, visual-inspection.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install eye-of-the-beholder@laicluse-agent-fieldkit
  claude plugins uninstall eye-of-the-beholder@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
