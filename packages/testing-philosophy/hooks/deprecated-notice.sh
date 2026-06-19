#!/bin/sh
cat <<'NOTICE'
testing-philosophy@leclause is DEPRECATED and has MOVED into the house-rules
plugin at house-rules@laicluse-agent-fieldkit. The testing-philosophy skill is
unchanged; it now ships from house-rules alongside programming-philosophy and
naming-is-hard. This plugin no longer ships any skills; this notice is its only
output.

To finish the move:
  claude plugins marketplace add epologee/laicluse-agent-fieldkit
  claude plugins install house-rules@laicluse-agent-fieldkit
  claude plugins uninstall testing-philosophy@leclause

Full migration guide: https://github.com/epologee/laicluse-agent-fieldkit/blob/main/docs/migration.md
NOTICE
