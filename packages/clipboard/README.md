# clipboard

Copy the core content of the last assistant answer to the macOS clipboard. Plain text by default, Slack-flavored rich text on request.

## Commands

### `/clipboard`

Copies the relevant content of the last answer to the clipboard as plain text via `pbcopy`. The skill picks the core content (code block, summary, answer body) rather than the full response wrapper.

### `/clipboard slack`

Copies as Slack rich text via `pbcopy-html`, preserving bold, italic, code spans, and code blocks when pasted into Slack.

## Requirements

macOS. Plain text mode uses the built-in `pbcopy` and works out of the box; the skill itself calls the `clipboard-copy` helper that ships inside `skills/clipboard/` of the installed plugin, so no install step is needed.

Rich text mode (`/clipboard slack`) drives `pbcopy-html`, a Swift script shipped with the plugin. Copy it onto your `$PATH` if you want to invoke `pbcopy-html` directly from a shell; `clipboard-copy --html` already resolves it relative to its own location. The marketplace is symlink-free to keep Windows consumers working, so install with `cp -f`:

```bash
SRC=$(jq -r '.plugins["clipboard@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)
cp -f "$SRC/skills/clipboard/pbcopy-html.swift" /usr/local/bin/pbcopy-html
```

Re-run after each `claude plugins update clipboard@leclause` so the installed copy matches the updated plugin.

## Installation

```bash
/plugin install clipboard@leclause
```
