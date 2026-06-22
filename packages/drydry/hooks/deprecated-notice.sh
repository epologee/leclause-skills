#!/bin/sh
cat <<'NOTICE'
drydry@leclause is DEPRECATED and has MOVED to drydry@laicluse-agent-fieldkit.
The orchestrator is unchanged: /drydry:drydry, with quick and audit modes.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install drydry@laicluse-agent-fieldkit
  claude plugins uninstall drydry@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
