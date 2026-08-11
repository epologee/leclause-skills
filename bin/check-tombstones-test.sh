#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
checker="$repo_root/bin/check-tombstones"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
output_file="$fixture/output"

mkdir -p "$fixture/.github/workflows" "$fixture/packages/example/.claude-plugin" "$fixture/packages/example/hooks" "$fixture/packages/example/skills/example"
cp "$repo_root/packages/drydry/hooks/hooks.json" "$fixture/packages/example/hooks/hooks.json"
cp "$repo_root/packages/drydry/hooks/deprecated-notice.sh" "$fixture/packages/example/hooks/deprecated-notice.sh"
printf '%s\n' '{"name":"example","description":"DEPRECATED. example moved.","version":"1.0.1"}' > "$fixture/packages/example/.claude-plugin/plugin.json"
printf '%s\n' '# example' > "$fixture/packages/example/README.md"
printf '%s\n' '# example skill' > "$fixture/packages/example/skills/example/SKILL.md"
printf '%s\n' '# Example marketplace' '' '| Plugin | Command |' '|--------|---------|' '| **example** | `/example` |' > "$fixture/README.md"
printf '%s\n' 'run: node packages/example/bin/helper' > "$fixture/.github/workflows/stale.yml"

if "$checker" "$fixture" >"$output_file" 2>&1; then
  echo "Expected deprecated runtime payload and an active catalog row to fail." >&2
  exit 1
fi

if ! grep -Fq "example still ships runtime payload: skills" "$output_file"; then
  cat "$output_file" >&2
  echo "Expected the tombstone check to identify runtime payload." >&2
  exit 1
fi

if ! grep -Fq "example is still active in the root README catalog" "$output_file"; then
  cat "$output_file" >&2
  echo "Expected the tombstone check to identify the stale catalog row." >&2
  exit 1
fi

if ! grep -Fq "example still has CI references to removed runtime payload" "$output_file"; then
  cat "$output_file" >&2
  echo "Expected the tombstone check to identify the stale CI reference." >&2
  exit 1
fi

rm -rf "$fixture/packages/example/skills"
rm "$fixture/.github/workflows/stale.yml"
sed -i.bak 's#`/example`#❌ deprecated#' "$fixture/README.md"
rm "$fixture/README.md.bak"

"$checker" "$fixture"
echo "check-tombstones enforces stripped payloads, CI references, and deprecated catalog rows"
