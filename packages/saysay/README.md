# saysay

Speech mode via the macOS `say` command. Once enabled, Claude speaks every response aloud, translating screen content into spoken language.

## Commands

### `/saysay`

Enter speech mode. Subsequent responses are spoken aloud after rendering.

### `/saysay off`

Exit speech mode.

## Requirements

macOS. Speech mode needs the macOS `say` binary plus two scripts shipped with the plugin. The marketplace is symlink-free to keep Windows consumers working, so install the scripts with `cp -f`:

```bash
SRC=$(jq -r '.plugins["saysay@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)
cp -f "$SRC/skills/saysay/saysay" /usr/local/bin/saysay
cp -f "$SRC/skills/saysay/say-phonetic" /usr/local/bin/say-phonetic
```

Re-run after each `claude plugins update saysay@leclause` so the installed copies match the updated plugin.

## Phonetic mappings

`say-phonetic` keeps a per-user pronunciation dictionary so that names, acronyms, and code identifiers come out the way you want. Mappings live in `~/.local/share/saysay/phonetics.json` (XDG).

```bash
say-phonetic add "kbd" "keyboard"
say-phonetic remove "kbd"
say-phonetic list
```

## Installation

```bash
/plugin install saysay@leclause
```
