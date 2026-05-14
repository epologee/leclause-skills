---
name: clipboard
user-invocable: true
description: Copy the core content of the last answer to the macOS clipboard via the clipboard-copy helper. Formats output based on content type. /clipboard slack for rich text.
allowed-tools:
  - Bash(jq *)
  - Bash(*clipboard-copy*)
effort: low
disable-model-invocation: true
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the clipboard plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("clipboard was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new clipboard`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

# Clipboard

Copy the core content of your last answer to the macOS clipboard via `clipboard-copy` (the helper that invokes `pbcopy` and `pbcopy-html` under the hood). No confirmation, no explanation. Just copy.

## Arguments

| Argument | Effect |
|----------|--------|
| *(none)* | Plain text via `clipboard-copy` (wraps `pbcopy`) |
| `slack` | Plain text formatted with Slack-native mrkdwn syntax (single-asterisk `*bold*`, bullet character `•`, no HTML). Slack auto-renders mrkdwn on send. Most reliable across Slack desktop, web, and mobile |

## Workflow

1. **Identify the core** of your last substantive answer, the useful content, not the meta-communication around it. If the last answer was itself a clipboard action, login, or other meta-operation, look further back for the last answer with actual content
2. **Determine the content type** (see table)
3. **Check the argument**: `slack` → convert to Slack-native mrkdwn (plain text) and use `clipboard-copy` (see section "Slack mode"). No argument → plain text via `clipboard-copy`
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

When the `slack` argument is provided, convert the content to Slack-native mrkdwn (plain text, NOT HTML) and call `clipboard-copy` (no `--html`):

```bash
IP=$(jq -r '.plugins["clipboard@leclause"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
if [ -z "$IP" ]; then
  echo "clipboard: clipboard@leclause is not installed or installed_plugins.json is missing. Run: claude plugins install clipboard@leclause" >&2
  exit 1
fi
. "$IP/bin/clipboard-paths.sh"
CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
"$CLIPBOARD_COPY" <<'CLIPBOARD'
[Slack mrkdwn content here]
CLIPBOARD
```

Why plain text mrkdwn and not HTML rich text: Slack desktop reads multiple pasteboard types (HTML, RTF, plain text) and the prediction of which one wins is unreliable across Slack desktop, web, and mobile. Slack-native mrkdwn in the plain-text type renders consistently on send: `*text*` becomes bold, `•` stays as bullet character, etc. HTML rich text paste either renders fully styled OR falls through to the HTML-stripped plain text fallback (no formatting at all), which is the failure mode that prompted this rewrite.

#### Markdown to Slack mrkdwn conversion

Slack mrkdwn is NOT regular Markdown. Use these substitutions:

| Standard Markdown | Slack mrkdwn |
|-------------------|--------------|
| `**bold**` | `*bold*` (SINGLE asterisk) |
| `*italic*` or `_italic_` | `_italic_` (SINGLE underscore) |
| `~~strike~~` | `~strike~` (SINGLE tilde) |
| `` `code` `` | `` `code` `` (unchanged) |
| ```` ```code``` ```` | ```` ```code``` ```` (unchanged) |
| `> quote` (single line) | `> quote` (unchanged) |
| `- list item` | `• list item` (literal bullet character, Slack does NOT auto-format `-`) |
| `1. numbered` | `1. numbered` (Slack does NOT auto-format, keep manually) |
| `# header` | `*header*` on its own line (Slack has no headers; emulate with bold) |
| `[text](url)` | `<url|text>` (angle-bracket form) |
| Bare URL | Leave as is, Slack auto-links |

#### Pitfalls

The following patterns LOOK harmless but break Slack rendering:

- **`>>>` at the start of a line triggers multi-line blockquote** that quotes everything to the end of the message. NEVER use `>>>` as a decorative separator. Use a different separator (e.g. `---`, blank line, or a labeled header line with `*Label:*`).
- **`>` at the start of a line triggers single-line blockquote**. If you do not want a quote, indent or rephrase.
- **`*` adjacent to non-space characters does not render as bold.** `*word*` works; `*>>>word*` does not (Slack does not recognize the boundary). Bold markers want whitespace or line-boundary on the outside.
- **Asterisks inside bold are literal.** `*foo *bar* baz*` confuses the parser. Reflow the text.
- **No headers.** `#`, `##` etc. render literally. Use a bold label on its own line.
- **Generic Markdown bullets (`-` or `*` at line start) stay literal in Slack.** Use the actual `•` character (U+2022) for visual bullets, or accept literal markers.

#### Tables in Slack mode

Slack mrkdwn has no table syntax. Wrap tables in a triple-backtick code block so the columns align in a monospace font:

````
```
Requirement                    | Current state           | Gap
-------------------------------|-------------------------|---------------------------
Load management at panel level | SensorMaxPowerLimiter   | Depends on sensor data
Priority per user profile      | Planner on departure    | Concept does not exist
```
````

Rules for tables in Slack:
- Wrap in ```` ``` ```` triple backticks (a Slack mrkdwn code block, rendered monospace)
- Columns separated by ` | ` (space-pipe-space)
- Header separated from body by `---...|---...` line
- Column width: pad with spaces so pipes align vertically

#### Example

Source content:
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
"$CLIPBOARD_COPY" <<'CLIPBOARD'
De job is goed uitgevoerd. Alle platforms uit `PLATFORM_TIMEOUTS` zijn *volledig* backfilled.
CLIPBOARD
```

Note the conversion: `**volledig**` (two asterisks, standard Markdown) becomes `*volledig*` (one asterisk, Slack mrkdwn). The backtick code remains unchanged.

## Confirmation

After copying, confirm with one line:

```
[type] copied: "[first ~30 characters]..."
```

Examples:
- `JSON copied: "{"name":"my-project","vers..."`
- `Code copied: "def calculate_price(kwh..."`
- `Slack message copied: "Hey team, de deploy van..."`
- `Slack mrkdwn copied: "De job is goed uitgevoerd. Alle platforms uit `PLATFORM_TIMEOUTS`..."`

## Looking back past meta-answers

If the immediately preceding answer has no copyable core (clipboard confirmation, login, skill invocation), look further back in the conversation. "Last answer" means the last answer with substantive content, not necessarily the chronologically last one.

## Nothing to copy

Only when there is no copyable content anywhere in the recent conversation (e.g. session just started, only questions asked), report briefly:

```
No copyable content found in the conversation.
```

