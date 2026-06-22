#!/bin/sh
cat <<'NOTICE'
inspire@leclause is DEPRECATED. The /inspire skill has MOVED into the lifeline
plugin at lifeline@laicluse-agent-fieldkit, paired with /ground.
The skill is unchanged. This plugin no longer ships any skills; this notice is
its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install lifeline@laicluse-agent-fieldkit
  claude plugins uninstall inspire@leclause
  claude plugins uninstall ground@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
