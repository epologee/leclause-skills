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

Kopieer de kern van je laatste antwoord naar het macOS clipboard via `clipboard-copy` (de helper die `pbcopy` en `pbcopy-html` onder water aanroept). Geen bevestiging, geen uitleg. Gewoon kopiëren.

## Argumenten

| Argument | Effect |
|----------|--------|
| *(geen)* | Plain text via `clipboard-copy` (wraps `pbcopy`) |
| `slack` | Rich text (HTML) via `clipboard-copy --html` (wraps `pbcopy-html`). Inline code, bold, en lijsten worden correct gerenderd bij plakken in Slack. Tabellen worden geconverteerd naar ASCII in een `<pre>` blok (Slack ondersteunt geen HTML tables) |

## Workflow

1. **Identificeer de kern** van je laatste inhoudelijke antwoord, de bruikbare content, niet de meta-communicatie eromheen. Als het laatste antwoord zelf een clipboard-actie, login, of andere meta-operatie was, kijk verder terug naar het laatste antwoord met daadwerkelijke content
2. **Bepaal het content type** (zie tabel)
3. **Check het argument**: `slack` → genereer HTML en gebruik `clipboard-copy --html` (zie sectie "Slack modus"). Geen argument → plain text via `clipboard-copy`
4. **Format en kopieer**
5. **Bevestig kort** wat er gekopieerd is (type + eerste paar woorden)

## Content Type Detectie

| Type | Herkenning | Formatting |
|------|-----------|------------|
| **JSON** | JSON object/array in antwoord | Pretty-printed JSON, intact laten |
| **Code** | Code block(s) in antwoord | Exacte code zonder markdown fences |
| **Command** | Shell command(s) | Commando's, één per regel |
| **Email/brief** | Aanhef, afronding, formele toon | Alinea's gescheiden door dubbele newline |
| **Slack/chat** | Informele toon, kort bericht | Doorlopende tekst, enkele newlines voor alinea's |
| **Lijst** | Opsomming, bullet points | Behoud list formatting met `- ` prefix |
| **Uitleg/proza** | Lopende tekst, uitleg | Doorlopende alinea's, dubbele newline tussen alinea's |
| **Tabel** | Tabeldata in antwoord | GitHub-flavored markdown tabel met `---|---|---` separator |

**Gemengde content:** Wanneer een antwoord code blocks bevat mét uitleg eromheen, wint "Code" altijd van "Uitleg/proza". De user wil de code kopiëren, niet de uitleg lezen in een ander venster. Kopieer alleen de code blocks, laat de prose weg.

## Formatting Regels

### Terminal-artefacten opschonen

Claude Code output bevat vaak:
- Newlines met leading spaces (terminal wrapping)
- Markdown formatting (`**bold**`, `` `code` ``, `### headers`)
- Bullet points als `- ` of `* `

**Altijd verwijderen:**
- Markdown bold/italic markers (`**`, `*`, `_`)
- Markdown header markers (`#`, `##`, etc.)
- Leading/trailing whitespace per regel

**Behouden:**
- Inline code backticks (`` `technische termen` `` blijven altijd staan)
- Structurele newlines (alinea-scheiding, list items)
- Indentatie die bij het content type hoort (code, JSON)

### Per type

**JSON:** Gebruik `jq .` formatting. Geen extra processing.

**Code:** Exacte code uit het code block. Geen markdown fences. Bij meerdere blocks: scheid met één lege regel.

**Command:** Alleen het commando zelf, geen uitleg. Meerdere commando's op aparte regels.

**Email/brief:** Platte tekst met alinea's. Geen markdown. Dubbele newline tussen alinea's.

**Slack/chat:** Doorlopende tekst. Enkele newline alleen bij echte alinea-wissel. Geen onnodige regelafbrekingen.

**Uitleg/proza:** Doorlopende alinea's. Geen bullets tenzij de originele structuur dat vereist. Terminal line-wrapping samenvoegen tot doorlopende zinnen.

**Tabel:** GitHub-flavored markdown met pipe-formatting en `---|---|---` separator tussen header en body. Plakbaar in GitHub issues, PR's, Notion, Slack (met GFM support).

## Kopiëren

`clipboard-copy` staat niet op `$PATH`. Elk code-blok source't `bin/clipboard-paths.sh` uit de clipboard plugin (via de `jq`-lookup in `installed_plugins.json`) en roept `resolve_clipboard_copy`. Die functie valideert dat de plugin geïnstalleerd is en dat de binary bestaat, en meldt anders met een bruikbare tip ("run `claude plugins install ...`" of "`claude plugins update ...`"). Geen bash "No such file or directory" meer als de cache achterloopt.

### Standaard (plain text)

Gebruik een heredoc om formatting-problemen te voorkomen:

```bash
. "$(jq -r '.plugins["clipboard@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)/bin/clipboard-paths.sh"
CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
"$CLIPBOARD_COPY" <<'CLIPBOARD'
[content here]
CLIPBOARD
```

**Let op:** `<<'CLIPBOARD'` (single quotes) is literal; variabelen, command substitution en backticks worden niet ge-expand. Dit is meestal wat je wilt. Gebruik alleen `<<"CLIPBOARD"` (dubbele quotes) wanneer je expliciet `$VAR`, `$(...)` of backticks wilt laten uitvoeren; dan moet content met letterlijke `$`, `` ` `` of `\` geescaped worden. Kies de heredoc-variant die het minste escaping vereist voor de specifieke content.

### Slack modus

Wanneer het argument `slack` is meegegeven, genereer HTML in plaats van plain text en roep `clipboard-copy --html`:

```bash
. "$(jq -r '.plugins["clipboard@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)/bin/clipboard-paths.sh"
CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
"$CLIPBOARD_COPY" --html <<'CLIPBOARD'
[HTML content here]
CLIPBOARD
```

`clipboard-copy --html` stuurt de HTML door `pbcopy-html.swift`, dat het als rich text op het clipboard zet (via `NSPasteboard`). Slack pikt dit op en rendert formatting correct. Daarnaast wordt een plain text fallback (HTML tags gestript) meegestuurd voor apps die geen rich text ondersteunen.

#### Markdown -> HTML conversie

Converteer de content naar HTML voordat je het aan `clipboard-copy --html` geeft:

| Markdown | HTML |
|----------|------|
| `` `code` `` | `<code>code</code>` |
| `**bold**` | `<b>bold</b>` |
| `- list item` | `<li>list item</li>` (in `<ul>`) |
| Lege regel | `<br><br>` |
| Regelafbreking | `<br>` (newlines in HTML source worden genegeerd door rich text paste, gebruik ALTIJD `<br>` voor line breaks) |
| Speciale tekens | **Escape NOOIT** met HTML entities (`&amp;`, `&gt;`, `&lt;`, `&quot;`). Veel apps (Slack, Notion, Teams) renderen entities letterlijk bij rich text paste: `&gt;` verschijnt als de tekst "&gt;" in plaats van ">". Schrijf `&`, `>`, `<` direct. Alleen escapen wanneer het teken een HTML-tag zou breken (bijv. `<` direct voor een letter). |

Wrap de volledige content NIET in `<html>` of `<body>` tags. Rich text paste verwacht HTML-fragmenten, geen volledige documenten.

#### Tabellen in Slack modus

Slack ondersteunt GEEN `<table>` HTML elementen. Een `<table>` wordt plat geslagen tot onleesbare tekst zonder structuur.

**Gebruik NOOIT `<table>`, `<tr>`, `<th>`, of `<td>` tags in Slack modus.**

Converteer tabellen naar ASCII format in een `<pre>` blok. Slack rendert `<pre>` als monospace codeblok, waardoor kolommen netjes uitgelijnd blijven.

```html
<pre>
Requirement                    | Current state           | Gap
-------------------------------|-------------------------|---------------------------
Load management at panel level | SensorMaxPowerLimiter   | Depends on sensor data
Priority per user profile      | Planner on departure    | Concept does not exist
</pre>
```

Regels voor ASCII tabellen in `<pre>`:
- Kolommen gescheiden door ` | ` (spatie-pipe-spatie)
- Header gescheiden van body door `---...|---...` regel
- Kolombreedte: pad met spaties zodat pipes verticaal uitlijnen
- Geen HTML tags binnen `<pre>` (geen `<code>`, `<b>`, etc.)

#### Voorbeeld

Markdown content:
```
De job is goed uitgevoerd. Alle platforms uit `PLATFORM_TIMEOUTS` zijn **volledig** backfilled.
```

Wordt:
```bash
. "$(jq -r '.plugins["clipboard@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)/bin/clipboard-paths.sh"
CLIPBOARD_COPY=$(resolve_clipboard_copy) || exit 1
"$CLIPBOARD_COPY" --html <<'CLIPBOARD'
De job is goed uitgevoerd. Alle platforms uit <code>PLATFORM_TIMEOUTS</code> zijn <b>volledig</b> backfilled.
CLIPBOARD
```

## Bevestiging

Na het kopiëren, bevestig met één regel:

```
[type] gekopieerd — "[eerste ~30 tekens]..."
```

Voorbeelden:
- `JSON gekopieerd — "{"name":"my-project","vers..."`
- `Code gekopieerd — "def calculate_price(kwh..."`
- `Slack bericht gekopieerd — "Hey team, de deploy van..."`
- `Tabel gekopieerd (slack/rich text) — "De job is goed uitgev..."`

## Terugkijken bij meta-antwoorden

Als het directe vorige antwoord geen kopieerbare kern heeft (clipboard bevestiging, login, skill invocatie), kijk verder terug in de conversatie. "Laatste antwoord" betekent het laatste antwoord met inhoudelijke content, niet per se het chronologisch laatste.

## Niet kopiëren

Alleen wanneer er nergens in de recente conversatie kopieerbare content te vinden is (bijv. sessie net gestart, alleen vragen gesteld), meld dit kort:

```
Geen kopieerbare content gevonden in de conversatie.
```

