---
name: clipboard
user-invocable: true
description: Use when the user types /clipboard to copy the core content of the last answer to the macOS clipboard via the clipboard-copy helper. Formats output based on content type. Supports /clipboard slack for rich text.
allowed-tools:
  - Bash(jq *)
  - Bash(*clipboard-copy*)
effort: low
disable-model-invocation: true
---

# Clipboard

Copy the core content of your last answer to the macOS clipboard via `clipboard-copy` (the helper that invokes `pbcopy` and `pbcopy-html` under the hood). No confirmation, no explanation. Just copy.

## Arguments

| Argument | Effect |
|----------|--------|
| *(none)* | Plain text via `clipboard-copy` (wraps `pbcopy`) |
| `slack` | Rich text (HTML) via `clipboard-copy --html` (wraps `pbcopy-html`). Inline code, bold, and lists render correctly when pasted into Slack. Tables are converted to ASCII in a `<pre>` block (Slack does not support HTML tables) |

## Workflow

1. **Identify the core** of your last substantive answer, the useful content, not the meta-communication around it. If the last answer was itself a clipboard action, login, or other meta-operation, look further back for the last answer with actual content
2. **Determine the content type** (see table)
3. **Check the argument**: `slack` → generate HTML and use `clipboard-copy --html` (see section "Slack mode"). No argument → plain text via `clipboard-copy`
4. **Format and copy**
5. **Confirm briefly** what was copied (type + first few words)

## Content Type Detection

| Type | Recognition | Formatting |
|------|-------------|------------|
| **JSON** | JSON object/array in answer | Pretty-printed JSON, leave intact |
| **Code** | Code block(s) in answer | Exact code without markdown fences |
| **Command** | Shell command(s) | Commands, one per line |
| **Email/letter** | Salutation, sign-off, formal tone | Paragraphs separated by double newline |
| **Slack/chat** | Informal tone, short message | Continuous text, single newlines between paragraphs |
| **List** | Enumeration, bullet points | Preserve list formatting with `- ` prefix |
| **Explanation/prose** | Running text, explanation | Continuous paragraphs, double newline between paragraphs |
| **Table** | Table data in answer | GitHub-flavored markdown table with `---|---|---` separator |

**Mixed content:** When an answer contains code blocks with surrounding explanation, "Code" always wins over "Explanation/prose". The user wants to copy the code, not read the explanation in another window. Copy only the code blocks, leave the prose out.

## Formatting Rules

### Cleaning up terminal artefacts

Claude Code output often contains:
- Newlines with leading spaces (terminal wrapping)
- Markdown formatting (`**bold**`, `` `code` ``, `### headers`)
- Bullet points as `- ` or `* `

**Always remove:**
- Markdown bold/italic markers (`**`, `*`, `_`)
- Markdown header markers (`#`, `##`, etc.)
- Leading/trailing whitespace per line

**Keep:**
- Inline code backticks (`` `technical terms` `` always stay)
- Structural newlines (paragraph breaks, list items)
- Indentation that belongs to the content type (code, JSON)

### Per type

**JSON:** Use `jq .` formatting. No extra processing.

**Code:** Exact code from the code block. No markdown fences. With multiple blocks: separate with one blank line.

**Command:** Only the command itself, no explanation. Multiple commands on separate lines.

**Email/letter:** Plain text with paragraphs. No markdown. Double newline between paragraphs.

**Slack/chat:** Continuous text. Single newline only at a real paragraph break. No unnecessary line breaks.

**Explanation/prose:** Continuous paragraphs. No bullets unless the original structure requires it. Merge terminal line-wrapping into continuous sentences.

**Table:** GitHub-flavored markdown with pipe-formatting and `---|---|---` separator between header and body. Pasteable in GitHub issues, PRs, Notion, Slack (with GFM support).

## Copying

`clipboard-copy` is not on `$PATH`. Each code block first resolves the installPath of clipboard via `jq` against `installed_plugins.json`, bails out if empty with a concrete install tip, then sources `bin/clipboard-paths.sh`, and calls `resolve_clipboard_copy`. That function validates the binary exists and reports otherwise with an update tip. No more bash "No such file or directory", neither from an uninstalled plugin nor from a stale cache.

### Default (plain text)

Use a heredoc to avoid formatting issues:

```bash
IP=$(jq -r '.plugins["clipboard@leclause"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
if [ -z "$IP" ]; then
  echo "clipboard: clipboard@leclause is not installed or installed_plugins.json is missing. Run: claude plugins install clipboard@leclause" >&2
  exit 1
fi
. "$IP/bin/clipboard-paths.sh"
CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
"$CLIPBOARD_COPY" <<'CLIPBOARD'
[content here]
CLIPBOARD
```

**Note:** `<<'CLIPBOARD'` (single quotes) is literal; variables, command substitution, and backticks are not expanded. This is usually what you want. Only use `<<"CLIPBOARD"` (double quotes) when you explicitly want `$VAR`, `$(...)` or backticks to be evaluated; then content with literal `$`, `` ` `` or `\` must be escaped. Choose the heredoc variant that requires the least escaping for the specific content.

### Slack mode

When the `slack` argument is provided, generate HTML instead of plain text and call `clipboard-copy --html`:

```bash
IP=$(jq -r '.plugins["clipboard@leclause"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
if [ -z "$IP" ]; then
  echo "clipboard: clipboard@leclause is not installed or installed_plugins.json is missing. Run: claude plugins install clipboard@leclause" >&2
  exit 1
fi
. "$IP/bin/clipboard-paths.sh"
CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
"$CLIPBOARD_COPY" --html <<'CLIPBOARD'
[HTML content here]
CLIPBOARD
```

`clipboard-copy --html` passes the HTML through `pbcopy-html.swift`, which places it on the clipboard as rich text (via `NSPasteboard`). Slack picks this up and renders formatting correctly. A plain text fallback (HTML tags stripped) is also included for apps that do not support rich text.

#### Markdown to HTML conversion

Convert the content to HTML before passing it to `clipboard-copy --html`:

| Markdown | HTML |
|----------|------|
| `` `code` `` | `<code>code</code>` |
| `**bold**` | `<b>bold</b>` |
| `- list item` | `<li>list item</li>` (in `<ul>`) |
| Empty line | `<br><br>` |
| Line break | `<br>` (newlines in HTML source are ignored by rich text paste, ALWAYS use `<br>` for line breaks) |
| Special characters | **NEVER escape** with HTML entities (`&amp;`, `&gt;`, `&lt;`, `&quot;`). Many apps (Slack, Notion, Teams) render entities literally on rich text paste: `&gt;` appears as the text "&gt;" instead of ">". Write `&`, `>`, `<` directly. Only escape when the character would break an HTML tag (e.g. `<` immediately before a letter). |

Do NOT wrap the full content in `<html>` or `<body>` tags. Rich text paste expects HTML fragments, not complete documents.

#### Tables in Slack mode

Slack does NOT support `<table>` HTML elements. A `<table>` is flattened to unreadable text without structure.

**NEVER use `<table>`, `<tr>`, `<th>`, or `<td>` tags in Slack mode.**

Convert tables to ASCII format in a `<pre>` block. Slack renders `<pre>` as a monospace code block, keeping columns neatly aligned.

```html
<pre>
Requirement                    | Current state           | Gap
-------------------------------|-------------------------|---------------------------
Load management at panel level | SensorMaxPowerLimiter   | Depends on sensor data
Priority per user profile      | Planner on departure    | Concept does not exist
</pre>
```

Rules for ASCII tables in `<pre>`:
- Columns separated by ` | ` (space-pipe-space)
- Header separated from body by `---...|---...` line
- Column width: pad with spaces so pipes align vertically
- No HTML tags inside `<pre>` (no `<code>`, `<b>`, etc.)

#### Example

Markdown content:
```
De job is goed uitgevoerd. Alle platforms uit `PLATFORM_TIMEOUTS` zijn **volledig** backfilled.
```

Becomes:
```bash
IP=$(jq -r '.plugins["clipboard@leclause"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
if [ -z "$IP" ]; then
  echo "clipboard: clipboard@leclause is not installed or installed_plugins.json is missing. Run: claude plugins install clipboard@leclause" >&2
  exit 1
fi
. "$IP/bin/clipboard-paths.sh"
CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
"$CLIPBOARD_COPY" --html <<'CLIPBOARD'
De job is goed uitgevoerd. Alle platforms uit <code>PLATFORM_TIMEOUTS</code> zijn <b>volledig</b> backfilled.
CLIPBOARD
```

## Confirmation

After copying, confirm with one line:

```
[type] copied: "[first ~30 characters]..."
```

Examples:
- `JSON copied: "{"name":"my-project","vers..."`
- `Code copied: "def calculate_price(kwh..."`
- `Slack message copied: "Hey team, de deploy van..."`
- `Table copied (slack/rich text): "De job is goed uitgev..."`

## Looking back past meta-answers

If the immediately preceding answer has no copyable core (clipboard confirmation, login, skill invocation), look further back in the conversation. "Last answer" means the last answer with substantive content, not necessarily the chronologically last one.

## Nothing to copy

Only when there is no copyable content anywhere in the recent conversation (e.g. session just started, only questions asked), report briefly:

```
No copyable content found in the conversation.
```

