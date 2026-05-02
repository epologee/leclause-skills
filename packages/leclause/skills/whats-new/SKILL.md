---
name: whats-new
user-invocable: true
description: Use ONLY when the operator types `/leclause:whats-new`. Reprints the CHANGELOG section for any installed leclause plugin without touching its broadcast sentinel. Argument is the plugin name (e.g. `gitgit`); without argument, lists every leclause plugin that ships a CHANGELOG.
argument-hint: "[plugin-name]"
---

# /leclause:whats-new

Toon de CHANGELOG-sectie van een geïnstalleerde leclause-plugin zonder de
post-update broadcast-sentinel te raken.

## Wat te doen

Resolve het install-path van de gevraagde plugin via
`~/.claude/plugins/installed_plugins.json` (canonieke bron). Wanneer de
operator een plugin-naam meegeeft:

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

Plaats de output letterlijk in een markdown blok in je antwoord. Geen
samenvatting, geen interpretatie; de CHANGELOG is canoniek.

Wanneer er GEEN argument is, geef een lijst:

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

Toon de lijst en de invocatie-vorm: "Roep `/leclause:whats-new <plugin>`
aan voor de CHANGELOG van een specifieke plugin."

## Wat NIET te doen

- Geen edit op enige CHANGELOG vanuit deze skill. Auteurs onderhouden hun
  CHANGELOG.md buiten Claude om.
- Geen bewerking van sentinels in `~/.claude/var/leclause/`. `--force` raakt
  ze niet; alleen de niet-force broadcast-blokken in de host-skills van een
  plugin schrijven.
- Geen aannames over welke plugins de broadcast-pattern hebben geadopteerd;
  de aanwezigheid van `bin/check-broadcast` is de waarheid.
