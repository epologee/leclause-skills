#!/bin/sh
cat <<'NOTICE'
ground@leclause is DEPRECATED. The /ground skill has MOVED into the lifeline
plugin at lifeline@laicluse-agent-fieldkit, paired with /inspire.
The skill is unchanged. This plugin no longer ships any skills; this notice is
its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install lifeline@laicluse-agent-fieldkit
  claude plugins uninstall ground@leclause
  claude plugins uninstall inspire@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
