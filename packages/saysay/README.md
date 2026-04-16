# saysay

Speech mode via the macOS `say` command. Once enabled, Claude speaks every response aloud, translating screen content into spoken language.

## Commands

### `/saysay`

Enter speech mode. Subsequent responses are spoken aloud after rendering.

### `/saysay off`

Exit speech mode.

## Requirements

macOS. Speech mode needs the macOS `say` binary plus two scripts shipped in `skills/saysay/` at the repo root. Symlink them into your PATH:

```bash
ln -s "$(pwd)/skills/saysay/saysay" /usr/local/bin/saysay
ln -s "$(pwd)/skills/saysay/say-phonetic" /usr/local/bin/say-phonetic
```

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
