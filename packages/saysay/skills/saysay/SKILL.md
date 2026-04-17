---
name: saysay
user-invocable: true
description: Use when the user types /saysay to enter speech mode, or /saysay off to exit. In speech mode, Claude speaks its output aloud via macOS say command after every response.
allowed-tools:
  - Bash(saysay *)
  - Bash(*| saysay*)
  - Bash(say-phonetic add *)
  - Bash(say-phonetic remove *)
  - Bash(say-phonetic list*)
disable-model-invocation: true
---

# Say Mode

Spraakuitvoer als vervanging van het scherm. Wanneer say mode actief is, spreek je je antwoord uit via het macOS `say` command na elke response. Tekst verschijnt nog steeds op het scherm, maar de gebruiker kijkt niet mee. De spraak IS de output.

## Activatie

| Command | Effect |
|---------|--------|
| `/saysay` | Activeer say mode |
| `/saysay off` | Deactiveer say mode |

Bij activatie: bevestig met spraak dat de modus actief is. Bij deactivatie: bevestig met spraak dat je stopt met praten.

## Stem

Altijd de systeemdefault stem, geen `-v` flag. Nooit. De Siri stem die in System Settings is ingesteld wordt gebruikt voor alles: Nederlands, Engels, code, alles.

Snelheid: `-r 240`

**Fonetische preprocessor:** Engelse woorden die de default stem verkeerd uitspreekt, kunnen fonetisch vertaald worden via `say-phonetic`. Dit is een opt-in dictionary per gebruiker, opgeslagen in `$XDG_DATA_HOME/saysay/phonetics.json` (default: `~/.local/share/saysay/phonetics.json`). De meeste Anglicismen worden prima uitgesproken, alleen probleemgevallen worden toegevoegd.

```bash
say-phonetic add retake rietéék
say-phonetic remove retake
say-phonetic list
```

**Fonetiek via natuurlijke taal:** Wanneer de gebruiker een fonetische mapping aangeeft in gewone taal, voer het `say-phonetic` command uit. Herkenbare patronen:

- "retake als rietéék" -> `say-phonetic add retake rietéék`
- "spreek retake uit als rietéék" -> `say-phonetic add retake rietéék`
- "retake niet meer fonetisch" -> `say-phonetic remove retake`

Dit werkt ook midden in een `/saysay` sessie. Voeg het woord toe en gebruik het direct in de volgende spraakuitvoer.

## Het say command

**Gebruik altijd `saysay` in plaats van `say`.** `saysay` handelt de volledige keten af: fonetische preprocessing, serialisatie (meerdere sessies praten na elkaar, niet door elkaar), en een kort scheidingsgeluid (Pop) bij het begin van elk bericht.

```bash
echo "De tekst die uitgesproken moet worden." | saysay --context "label"
```

**Nooit dit:** `say -r 240` (direct say, geen serialisatie)
**Nooit dit:** `say-phonetic process | say -r 240` (oude pipeline)
**Nooit dit:** heredoc syntax (`saysay <<'SAY'`), dat sprawlt uit in de tool call display
**Altijd dit:** `echo "tekst" | saysay --context "label"`

Default snelheid is `-r 240`. Overschrijfbaar: `echo "tekst" | saysay -r 180 --context "label"`.

`saysay` blokt in de shell: het wacht tot het bericht is uitgesproken. Maar roep het ALTIJD aan met `run_in_background: true` op de Bash tool call. Zo kan de tekst output en het prompt doorgaan terwijl de spraak loopt. De Bash call stopt automatisch wanneer het uitspreken klaar is.

### Sessie-context

Elke saysay-aanroep bevat `--context "label"` zodat de gebruiker bij meerdere parallelle sessies hoort welke sessie spreekt. Het label is max twee woorden en beschrijft het **thema** van het gesprek, niet de branch of directory.

Bij activatie van say mode: bepaal een kort thematisch label op basis van het gesprek tot nu toe. Gebruik dat label consistent in alle saysay-aanroepen van de sessie.

Voorbeelden:
- Gesprek over saysay verbeteringen -> `--context "saysay fixes"`
- Gesprek over een calculator feature -> `--context "calculator"`
- Gesprek over hook configuratie -> `--context "hook config"`

Zonder `--context` valt saysay terug op git remote + branch (max 2 woorden). Met `--no-context` wordt de prefix helemaal weggelaten.

## Vertalen naar spraak

De spraak vervangt het scherm. Dat betekent: niet voorlezen wat er staat, maar overbrengen wat de gebruiker moet weten. Dit is de kern van de skill.

### Principes

- **Vat samen op het juiste niveau.** Een tabel met 10 rijen wordt niet cel voor cel voorgelezen. "Er zijn tien resultaten, de belangrijkste zijn X en Y" is beter.
- **Structuur wordt intonatie.** Bullet points, headers, en secties bestaan niet in spraak. Gebruik overgangszinnen: "Verder is er nog...", "Het belangrijkste punt is..."
- **Technische details doseren.** Een bestandspad of korte code snippet kan letterlijk. Een heel diff of lange stack trace niet. Beschrijf de essentie: "De error zit in regel 42 van het user model, een nil reference op het email veld."
- **Leestekens weglaten.** Geen "punt", "komma", "aanhalingsteken". De tekst moet klinken als gesproken taal.
- **Getallen en speciale tekens.** Spreek uit: `127.0.0.1` wordt "honderdzevenentwintig punt nul punt nul punt een". `$HOME` wordt "dollar HOME". Maar wees pragmatisch: als een waarde niet relevant is, noem het niet.

### Wat WEL letterlijk

- Korte code snippets (methodenaam, variabele, commando)
- Foutmeldingen (de eerste regel)
- Bestandsnamen en paden (wanneer de gebruiker ze nodig heeft)
- Getallen die ertoe doen

### Wat NIET letterlijk

- Markdown formatting (`**`, `#`, `` ` ``, `---`)
- Tabellen (beschrijf de inhoud)
- Lange diffs (beschrijf wat er veranderd is)
- Herhalende patronen ("en dan nog drie vergelijkbare entries")
- URLs en links (staan al op het scherm, voorlezen voegt niets toe)

### Tool calls

Tijdens het werken (code schrijven, bestanden lezen, tests draaien) hoef je niet elke tool call uit te spreken. Spreek de conclusie uit, niet het proces. "Tests zijn groen" is genoeg, niet "ik run nu bundle exec rspec spec slash models en het resultaat is twaalf voorbeelden nul failures".

Uitzondering: als een tool call faalt of iets onverwachts oplevert, spreek dat wel uit.

## Voorbeeld

Stel de gebruiker vraagt "wat is de status van de test suite?" en je runt de tests.

**Scherm (tekst output):**
```
Tests: 847 examples, 2 failures
- spec/models/user_spec.rb:42 - expected nil to eq "test@example.com"
- spec/services/billing_spec.rb:108 - timeout after 5 seconds
```

**Spraak:**
```bash
echo "De test suite heeft twee failures op achthonderdzevenenveertig tests. De eerste is in het user model, een nil waarde waar een emailadres verwacht wordt, op regel 42. De tweede is een timeout in de billing service op regel 108." | saysay
```

## Combinatie met andere skills

Wanneer say mode actief is en een andere skill output produceert (recap, changelog, analyse), moet die output ook gesproken worden. Niet alleen een intro ("hier is de recap") maar de inhoud zelf, vertaald naar spraak. De tekst op het scherm bevat de details (tabellen, paden, lijsten), de spraak vat samen wat de user moet weten om te kunnen handelen.

**Fout:** `echo "Hier is de recap." | saysay` gevolgd door ongesproken tekst.
**Goed:** `echo "We waren bezig met X. De status is Y. Er staan nog Z dingen open, namelijk..." | saysay` met de volledige inhoud vertaald naar spraak.

## Persistent mode

Say mode blijft actief totdat de gebruiker `/saysay off` zegt. Elke response eindigt met een `say` call. Dit geldt ook voor korte antwoorden, foutmeldingen, en tussenstappen. Als je niks substantieels te melden hebt, hoef je niet te spreken (bijv. een pure tool call zonder conclusie).
