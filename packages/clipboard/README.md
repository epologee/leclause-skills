# clipboard

Copy the core content of the last assistant answer to the macOS clipboard. Plain text by default, Slack-flavored rich text on request.

## Commands

### `/clipboard`

Copies the relevant content of the last answer to the clipboard as plain text via `pbcopy`. The skill picks the core content (code block, summary, answer body) rather than the full response wrapper.

### `/clipboard slack`

Copies as Slack rich text via `pbcopy-html`, preserving bold, italic, code spans, and code blocks when pasted into Slack.

## Requirements

macOS. Plain text mode uses the built-in `pbcopy`.

Rich text mode requires `pbcopy-html`, a Swift script shipped with the plugin. Symlink it into your PATH:

```bash
ln -s "$(pwd)/packages/clipboard/skills/clipboard/pbcopy-html.swift" /usr/local/bin/pbcopy-html
```

## Installation

```bash
/plugin install clipboard@leclause
```
