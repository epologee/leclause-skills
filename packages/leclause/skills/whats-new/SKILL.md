---
name: whats-new
user-invocable: true
description: Use ONLY when the operator types `/leclause:whats-new`. Reprints the CHANGELOG section for any installed leclause plugin without touching its broadcast sentinel. Argument is the plugin name (e.g. `gitgit`); without argument, lists every leclause plugin that ships a CHANGELOG.
argument-hint: "[plugin-name]"
---

# /leclause:whats-new

Show the CHANGELOG section of an installed leclause plugin without touching
the post-update broadcast sentinel.

## What to do

Resolve the install path of the requested plugin via
`~/.claude/plugins/installed_plugins.json` (canonical source). When the
operator provides a plugin name:

```bash
PLUGIN="<arg>"
INSTALL=$(jq -r --arg name "${PLUGIN}@leclause" \
  '.plugins[$name][0].installPath // empty' \
  ~/.claude/plugins/installed_plugins.json)
if [ -z "$INSTALL" ]; then
  echo "Plugin ${PLUGIN}@leclause is not installed."
  exit 0
fi
if [ ! -x "$INSTALL/bin/check-broadcast" ]; then
  echo "Plugin ${PLUGIN}@leclause has no check-broadcast helper; CHANGELOG support not adopted yet."
  exit 0
fi
node "$INSTALL/bin/check-broadcast" --force
```

Place the output verbatim in a markdown block in your response. No
summary, no interpretation; the CHANGELOG is canonical.

When there is NO argument, produce a list:

```bash
jq -r '.plugins | to_entries[] | select(.key | endswith("@leclause")) | .key' \
  ~/.claude/plugins/installed_plugins.json | while read -r entry; do
  plugin="${entry%@leclause}"
  install=$(jq -r --arg k "$entry" '.plugins[$k][0].installPath // empty' \
    ~/.claude/plugins/installed_plugins.json)
  if [ -x "$install/bin/check-broadcast" ]; then
    echo "- $plugin"
  fi
done
```

Show the list and the invocation form: "Run `/leclause:whats-new <plugin>`
for the CHANGELOG of a specific plugin."

## What NOT to do

- No edits to any CHANGELOG from within this skill. Authors maintain their
  CHANGELOG.md outside Claude.
- No modifications to sentinels in `~/.claude/var/leclause/`. `--force` does
  not touch them; only the non-force broadcast blocks in a plugin's host
  skills write them.
- No assumptions about which plugins have adopted the broadcast pattern;
  the presence of `bin/check-broadcast` is the source of truth.
