#!/bin/sh
cat <<'NOTICE'
whywhy@leclause is DEPRECATED and has MOVED to whywhy@laicluse-agent-fieldkit.
The skill is unchanged: /whywhy [count] <question>, the configurable why-chain.
This plugin no longer ships any skills; this notice is its only output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install whywhy@laicluse-agent-fieldkit
  claude plugins uninstall whywhy@leclause

Full migration guide: https://github.com/epologee/leclause-skills/blob/main/docs/migration.md
NOTICE
