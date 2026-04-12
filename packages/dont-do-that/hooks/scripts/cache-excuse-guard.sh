#!/bin/bash
# Cache excuse guard
# Stop hook: blocks Claude from blaming "cache" for issues on localhost.
# On development servers, cache is almost never the real cause.
# Forces investigation of the actual root cause.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/read-assistant-text.sh"

INPUT=$(cat)
is_stop_hook_active "$INPUT" && exit 0

ASSISTANT_TEXT=$(read_assistant_text "$INPUT" 2000 "cache-guard")
[ -z "$ASSISTANT_TEXT" ] && exit 0

is_wip_mode "$ASSISTANT_TEXT" && exit 0

FOUND=$(echo "$ASSISTANT_TEXT" \
  | grep -ciE "(het probleem is|komt door|ligt aan|veroorzaakt door|schuld van).*(cache|gecachet)|(cache|gecachet).*(stale|verouderd|invalide|probleem|oorzaak)|wacht.*(cache|10 minuten).*invalideer|browser.*(cache|gecachet|oude.*versie)|hard.refresh|Cmd.*Shift.*R|esbuild.*watcher.*(niet|cache)|oude.*(JS|javascript|bundle|assets)")

if [ "$FOUND" -gt 0 ] 2>/dev/null; then
  echo '{"decision":"block","reason":"Als je cache noemde als oorzaak: cache is vrijwel nooit de oorzaak op localhost. Onderzoek de werkelijke root cause."}'
fi
