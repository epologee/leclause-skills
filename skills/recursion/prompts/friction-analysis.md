# Recursion Friction Analysis

Instructies voor de friction-analyse agent. Je analyseert gesprekssessies om
patronen te vinden waar user en Claude langs elkaar heen praten, doelen niet
worden gehaald, of Claude herhaaldelijk gecorrigeerd moet worden.

## Doel

Produceer concrete voorstellen voor CLAUDE.md aanpassingen of nieuwe skills
die terugkerende friction patronen structureel aanpakken.

## Databronnen

### Primair: sessie-JSONLs (volledige gesprekken)

Locatie: `~/.claude/projects/<project-dir>/<session-id>.jsonl`

Formaat: line-delimited JSON. Elke regel heeft een `type` veld:
- `type: "user"` en `type: "assistant"` bevatten gesprekscontent
- Content zit in `d["message"]["content"]` (string of lijst van content blocks)
- Content blocks: `{"type": "text", "text": "..."}` voor tekst

**Scoping:** Analyseer alleen sessies gewijzigd sinds de vorige recursion run.
Check `last_run` in state.md en filter op file modification time.

**Sampling:** Sessies >500 regels: lees eerste 150 en laatste 150 regels.
Dit vangt zowel de initiële opzet als de afronding (waar friction vaak zit).

### Secundair: history.jsonl (alleen user-berichten)

Locatie: `~/.claude/history.jsonl`

Formaat: `{"display": "...", "timestamp": ..., "project": "...", "sessionId": "..."}`

Gebruik voor snelle scan op correctie-patronen over alle projecten heen.
Filter op timestamp sinds vorige run.

### Tertiair: git log

`git log --all --oneline` voor revert-patronen, fix-the-fix commits.

## Friction Patronen

### 1. Correcties (severity: medium-high)

User corrigeert Claude direct na een antwoord.

**Signaalwoorden in user-berichten:**
- "nee", "niet dat", "ik bedoelde", "dat klopt niet"
- "stop met", "dat zei ik toch al", "lees nog eens"
- Korte correcties na lange Claude-output (bijv. "X moet Y zijn")
- Herformulering van dezelfde opdracht

**Analyse per gevonden correctie:**
- Wat zei Claude dat gecorrigeerd moest worden?
- Was dit een interpretatiefout (intent verkeerd gelezen)?
- Was dit een kennisfout (feit onjuist)?
- Was dit een conventie-schending (bestaande regel niet gevolgd)?
- Is er een CLAUDE.md regel die dit had moeten voorkomen?

### 2. Overclaimed Confidence (severity: high)

Claude presenteert onzekere informatie als feit.

**Signalen:**
- User vraagt "weet je dat zeker?", "kun je dat onderbouwen?"
- User vraagt om verificatie van een claim
- Claude geeft toe dat iets "een gok" was
- Claude trekt een eerdere bewering in

**Analyse:** Dit is het gevaarlijkst wanneer het in externe output terechtkomt
(GitHub issues, PR beschrijvingen, documenten). Markeer altijd of de
overclaimed info in een extern artefact belandde.

### 3. Compliance Reflex (severity: low-medium)

Claude stopt en vraagt toestemming voor iets dat al in scope was.

**Signalen:**
- "Wil je dat ik...?" na een expliciete opdracht
- "Zal ik ook...?" voor iets dat de user al noemde
- Samenvatting tussen twee tool calls in plaats van doorwerken
- User antwoordt met "ja", "doe maar", "uiteraard"

**Analyse:** Check of de CLAUDE.md "doorwerken" sectie dit patroon al dekt.
Zo ja: het is een compliance-probleem, geen regel-probleem. Zo nee: stel
een regel voor.

### 4. Premature Action (severity: medium)

Claude begint te implementeren voordat de opdracht helder is.

**Signalen:**
- User stelt een vraag, Claude maakt meteen wijzigingen
- User zegt "laat maar" of "revert" kort na een wijziging
- User herformuleert de opdracht na een eerste poging

**Analyse:** Was de user aan het brainstormen of aan het opdracht geven?
Verschil: vraagvorm ("willen we niet...?") vs. imperatiefvorm ("doe X").

### 5. Doel-abandonment (severity: high)

Een gesprek begint met doel X maar eindigt zonder dat X bereikt is.

**Signalen:**
- Eerste user-bericht noemt een duidelijk doel
- Laatste 10 berichten gaan over iets anders
- Geen bevestiging dat het oorspronkelijke doel bereikt is
- Sessie eindigt met een tangentieel onderwerp

**Analyse:** Was het doel expliciet verlaten (user koos andere richting) of
impliciet verloren (afdwaling zonder bewuste keuze)?

### 6. Downgrade-spiraal (severity: high)

Claude probeert aanpak A, dan B, dan C, met afnemende kwaliteit.

**Signalen:**
- Drie of meer tool-calls met vergelijkbare intent maar andere aanpak
- Revert-achtige patronen (code schrijven, dan terugdraaien, dan anders)
- User zegt "probeer X" na een mislukte poging (reactief in plaats van proactief)

**Analyse:** Check of de CLAUDE.md "iteratief downgraden is verboden" dit
patroon al dekt. Als de regel bestaat maar niet gevolgd wordt, is het een
compliance-probleem. Als de regel niet dekt wat er gebeurde, stel een
aanscherping voor.

### 7. Herhaalde Instructie (severity: medium)

Dezelfde instructie komt in meerdere sessies terug.

**Detectie via history.jsonl:** Zoek naar semantisch vergelijkbare user-berichten
(niet letterlijk dezelfde tekst, maar dezelfde intentie) over meerdere sessies.

**Analyse:** Als de user dezelfde instructie herhaaldelijk moet geven, ontbreekt
er een CLAUDE.md regel, een skill, of een hook die dit automatisch afdwingt.

### 8. Self-improvement Audit (severity: high, altijd uitvoeren)

`/self-improvement` invocaties zijn de hoogste-signaal friction indicator:
de user zegt letterlijk "dit moet structureel anders." Analyseer ELKE
`/self-improvement` in de geanalyseerde sessies.

**Detectie:** Zoek in user-berichten naar `/self-improvement` (letterlijk).

**Per invocatie, analyseer de volledige keten:**

1. **Trigger**: Wat was het friction-moment dat de invocatie uitlokte?
   Lees de 3-5 user-berichten vóór de invocatie. Wat ging er mis?
2. **Instructie**: Wat vroeg de user aan self-improvement om te doen?
   Soms zit de instructie in hetzelfde bericht, soms in het bericht erna.
3. **Uitvoering**: Wat deed self-improvement daadwerkelijk?
   Lees de assistant-berichten na de invocatie. Welke bestanden werden
   gewijzigd? Welke regels werden toegevoegd/aangepast?
4. **Effectiviteit**: Loste de wijziging het oorspronkelijke probleem op?
   - Check of hetzelfde friction-patroon in latere sessies terugkomt
   - Check of de toegevoegde regel/skill concreet genoeg is om het
     patroon te voorkomen (of te vaag/breed)
   - Check of de regel op de juiste plek staat (CLAUDE.md vs. skill vs. hook)
5. **Gemiste kansen**: Had self-improvement meer moeten doen?
   - Was er een breder patroon dat niet geadresseerd werd?
   - Had een hook het beter afgedwongen dan een CLAUDE.md regel?
   - Had een bestaande skill aangescherpt moeten worden?

**Output per invocatie:**

```markdown
#### Self-improvement: [korte beschrijving trigger]
- **Trigger**: [wat ging er mis]
- **Gevraagde actie**: [wat de user wilde]
- **Uitgevoerde actie**: [wat er daadwerkelijk veranderde]
- **Effectiviteit**: geslaagd / gedeeltelijk / gefaald
- **Reden**: [waarom wel/niet effectief]
- **Voorstel**: [vervolgactie als de fix onvolledig was]
```

**Concentratie-analyse:** `/self-improvement` komt typisch in bursts:
3-12 invocaties binnen 30-90 minuten, meerdere keren per dag. Dat is
normaal gebruik, niet een alarmsignaal. De interessante vraag is niet
frequentie maar *thematische herhaling*: komen dezelfde type correcties
(bijv. taalkeuze, naming, tool gebruik) steeds terug over meerdere
clusters heen? Dat duidt op een self-improvement die het onderliggende
probleem niet structureel oploste. Analyseer per thema of eerdere
fixes effectief waren, niet per tijdsinterval.

## Output Formaat

```markdown
## Friction Analyse [datum]

### Sessies Geanalyseerd
- N sessies, M projecten, periode X-Y

### Bevindingen

#### High Severity
1. **[patroon-type]** sessie: beschrijving
   - User-bericht: "quote"
   - Claude-fout: wat er misging
   - Root cause: waarom
   - Voorstel: CLAUDE.md regel / skill / hook
   - Impact: hoe vaak dit patroon voorkomt

#### Medium Severity
...

#### Low Severity
...

### Self-improvement Audit
Per `/self-improvement` invocatie: trigger, actie, effectiviteit, voorstel.
Bij concentratie (3+ in een week): overkoepelend patroon benoemen.

### Voorgestelde Acties
Per voorstel:
- Type: CLAUDE.md aanpassing / nieuwe skill / hook / bestaande skill wijziging
- Beschrijving: concrete wijziging
- Verwachte impact: welk friction patroon dit aanpakt
- Risico: kans op false positives of ongewenste neveneffecten
```

## Privacy

- Citeer user-berichten alleen met genoeg context voor de analyse
- Geen projectnamen, bedrijfsnamen, of persoonlijke namen in de output
  die naar buiten gaat (recap, notificaties)
- Sessie-IDs zijn intern, niet extern delen
- Code-fragmenten uit sessies niet overnemen in voorstellen
