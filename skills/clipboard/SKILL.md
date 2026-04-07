---
name: clipboard
description: Use when the user types /clipboard to copy the core content of the last answer to the macOS clipboard via pbcopy. Formats output based on content type. Supports /clipboard slack for rich text.
allowed-tools:
  - Bash(pbcopy *)
  - Bash(*pbcopy-html*)
effort: low
disable-model-invocation: true
---

# Clipboard

Kopieer de kern van je laatste antwoord naar het macOS clipboard via `pbcopy`. Geen bevestiging, geen uitleg. Gewoon kopiëren.

## Argumenten

| Argument | Effect |
|----------|--------|
| *(geen)* | Plain text via `pbcopy` (standaard) |
| `slack` | Rich text (HTML) via `pbcopy-html` (inline code, bold, en lijsten worden correct gerenderd bij plakken in Slack). Tabellen worden geconverteerd naar bold-label lijsten (Slack ondersteunt geen HTML tables) |

## Workflow

1. **Identificeer de kern** van je laatste inhoudelijke antwoord, de bruikbare content, niet de meta-communicatie eromheen. Als het laatste antwoord zelf een clipboard-actie, login, of andere meta-operatie was, kijk verder terug naar het laatste antwoord met daadwerkelijke content
2. **Bepaal het content type** (zie tabel)
3. **Check het argument**: `slack` → genereer HTML en gebruik `pbcopy-html` (zie sectie "Slack modus"). Geen argument → plain text via `pbcopy`
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

### Standaard (plain text)

Gebruik een heredoc om formatting-problemen te voorkomen:

```bash
pbcopy <<'CLIPBOARD'
[content here]
CLIPBOARD
```

**Let op:** Bij content met single quotes, gebruik `<<"CLIPBOARD"` (dubbele quotes) of escape. Kies de heredoc-variant die het minste escaping vereist voor de specifieke content.

### Slack modus

Wanneer het argument `slack` is meegegeven, genereer HTML in plaats van plain text en gebruik `pbcopy-html`:

```bash
pbcopy-html <<'CLIPBOARD'
[HTML content here]
CLIPBOARD
```

`pbcopy-html` zet de HTML als rich text op het clipboard (via `NSPasteboard`). Slack pikt dit op en rendert formatting correct. Daarnaast wordt een plain text fallback (HTML tags gestript) meegestuurd voor apps die geen rich text ondersteunen.

#### Markdown -> HTML conversie

Converteer de content naar HTML voordat je het aan `pbcopy-html` geeft:

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
pbcopy-html <<'CLIPBOARD'
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

