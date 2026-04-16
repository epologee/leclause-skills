# how-plugins-work

Living document explaining how Claude Code plugin naming, skill resolution, and the `plugin:skill` invocation pattern actually behave in practice. Based on empirical testing, updated when behavior shifts.

## Commands

### `/how-plugins-work`

Loads the current understanding: how slash-command names map to plugins, how sub-skills resolve, when the `plugin:skill` form is required, and the gotchas around plugin caching.

## Auto-trigger

Activates when diagnosing:

- "Unknown command" errors after a fresh install
- Slash-command autocomplete misses
- Confusion between plugin name, skill name, and command name
- Sub-skills that work in isolation but not when invoked from another skill

## Why a living document

Plugin behavior is undocumented in places and shifts between Claude Code releases. Rather than guess from memory, the skill records what the latest tests show and updates when something changes.

## Installation

```bash
/plugin install how-plugins-work@leclause
```
