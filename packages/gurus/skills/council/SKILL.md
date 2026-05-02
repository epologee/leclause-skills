---
name: council
user-invocable: true
description: Vijf advisors vallen een idee, beslissing of plan vanuit vijf hoeken aan. Pre-mortem, first-principles, opportunity-finder, stranger, action. Responses worden geanonimiseerd en blind peer-reviewed; een chairman synthetiseert één verdict. Triggers op /gurus:council, board of advisors, critical review panel, wanneer je twijfelt of Claude alleen maar meegaand is.
effort: high
---

# Council of Five Advisors

> **Preflight.** Deze skill dispatcht elf `gurus:sonnet-max` agents in twee parallelle rondes plus een chairman. Die agent bestaat vanaf plugin-versie 1.0.8. Wanneer de dispatch faalt met "unknown subagent_type: gurus:sonnet-max", draai `claude plugins update gurus@leclause` en probeer opnieuw.

Claude is standaard een YES-MAN. Deze skill bouwt een tegengewicht in. Vijf adversariële agents kijken naar jouw vraag vanuit vijf fundamenteel verschillende hoeken, lezen elkaars werk blind, en een chairman maakt er één verdict van. Geen diplomatie, geen "het hangt ervan af". De lens is het antwoord.

Pattern gebaseerd op Ole Lehmann's "board of advisors" skill, zelf geïnspireerd op parallel LLM-critique patronen die o.a. Andrej Karpathy bepleit. Single-vendor variant: alle vijf advisors plus de chairman draaien op `gurus:sonnet-max`.

## Wanneer te gebruiken

- Een beslissing voelt als "moet ik X of Y?"
- Een plan voelt te glad, te rustig goedgekeurd
- Een idee is nog niet getest tegen iemand die niet uit jouw hoofd komt
- Claude's vorige antwoord voelt sycophantic

Niet voor code review; daarvoor is `/gurus:software`. Niet voor zuiver feitelijke vragen; daarvoor is `/ground` of `/inspiratie`.

**Kosten en latency.** Eén council-invocatie dispatcht elf `gurus:sonnet-max` agents op `effort: max` (vijf lenzen, vijf peer reviews, één chairman). De twee review-fasen lopen parallel, dus de typische doorlooptijd is 2 tot 4 minuten en de tokenconsumptie is substantieel. Gebruik het wanneer de beslissing de kosten rechtvaardigt; voor snelle sanity-checks is `/gurus:software` op een enkele Sonnet of een direct gesprek goedkoper.

## Het panel

| # | Advisor | Lens |
|---|---------|------|
| 1 | **Pre-mortem** | Neemt aan dat het idee faalt en probeert dat te bewijzen. Zoekt de kill-scenarios, de verborgen single points of failure, de manier waarop dit over zes maanden een blunder blijkt. |
| 2 | **First-principles** | Strijkt alle aannames weg en bouwt het probleem van scratch opnieuw op. Vraagt: wat is hier werkelijk het probleem, los van de voorgestelde oplossing? Negeert gewoonte, precedent, "we hebben altijd X gedaan". |
| 3 | **Opportunity-finder** | Zoekt de grotere kans die jij te dichtbij zit om te zien. Als het voorstel slaagt, wat staat ernaast dat tien keer meer waard is? Wat is de echte partij waar dit een stap naartoe is? |
| 4 | **Stranger** | Heeft nul context over jou, jouw geschiedenis, jouw domein. Reageert als een volwassene die dit probleem voor het eerst hoort. Stelt de naïeve vragen die insiders niet meer durven te stellen. |
| 5 | **Action** | Geeft alleen om wat je daadwerkelijk nu gaat doen. Abstracties, principes, theorieën: irrelevant. Concrete volgende stap, deze week, meetbaar. Als je dit niet in één zin kan beschrijven, heb je geen plan. |

Kenmerkende spanning: Pre-mortem vs Opportunity-finder (risico vs kans), First-principles vs Stranger (deep context vs zero context), Action vs alle anderen (beweging vs analyse).

## Protocol

### Stap 1: Brief vaststellen

Vat de vraag, beslissing of het plan samen in maximaal 3 zinnen neutrale prose. Dit is wat elke advisor krijgt. Geen leading language ("dit mooie idee"), geen verdediging. Ruwe situatie.

Wanneer onduidelijk wat de vraag exact is: stel **één** verhelderende vraag aan de gebruiker voordat je dispatcht. Vijf agents op een onduidelijke brief is tokenverspilling.

### Stap 2: Vijf agents parallel dispatchen

Eén message met 5 parallelle `Agent` calls, elk met `subagent_type: "gurus:sonnet-max"`. Lens-specifieke prompts, geen onderling bewustzijn.

**Prompt template per advisor** (vul de lens-specifieke instructie in):

```
Je bent advisor [NAAM] in een board of advisors review. Je rol is één specifieke lens, niet een algemeen oordeel.

[LENS-INSTRUCTIE uit de tabel hieronder]

Je weet niet wie de andere advisors zijn. Je weet dat er vier andere lenzen zijn, maar niet welke. Je werk wordt anoniem peer-reviewed.

## De situatie

[BRIEF uit stap 1]

## Output (volg dit format exact)

### Kernobservatie
Eén alinea van 3 tot 5 zinnen. Wat zie je vanuit deze lens dat de persoon mogelijk niet ziet?

### Specifieke punten
Genummerde lijst van 3 tot 5 punten. Per punt:
- Wat: concreet, niet abstract
- Waarom vanuit deze lens: expliciet verankerd in je rol
- Wat de persoon hiermee zou moeten doen: actionable

### Wat je NIET zegt
Noem één ding dat andere advisors waarschijnlijk gaan zeggen en waar jij bewust van afblijft, omdat het niet jouw lens is.

Geen diplomatie. Geen "enerzijds/anderzijds". Spreek vanuit je lens.
```

**Lens-instructies:**

1. **Pre-mortem**: "Je neemt aan dat dit idee over zes maanden een blunder is. Je taak is die blunder reconstrueren voordat hij gebeurt. Zoek de faalmodi die nog onzichtbaar zijn: afhankelijkheden die breken, aannames die kloppen totdat ze niet meer kloppen, de menselijke dynamiek die gaat rotten. Schrijf alsof je de autopsie houdt."

2. **First-principles**: "Je strijkt elke aanname weg: precedent, gewoonte, 'we doen dit altijd zo', 'dit is standaard'. Wat zijn de daadwerkelijke constraints, los van gewoonte of precedent? Wat is hier daadwerkelijk het probleem? Wat als er geen bestaande oplossing was: hoe zou iemand dit van scratch oplossen?"

3. **Opportunity-finder**: "Je zoekt de grotere kans die deze persoon te dichtbij zit om te zien. Als het voorstel slaagt, wat staat ernaast dat tien keer meer waard is? Als het voorstel een stap is: een stap naar wat? Welke poort gaat open? Welke grotere partij wordt bereikbaar?"

4. **Stranger**: "Je hebt nul context over deze persoon, dit bedrijf, dit domein. Je bent een volwassene die dit probleem net hoort. Stel de naïeve vragen die insiders niet meer durven te stellen. Waarom is X überhaupt een probleem? Wat wordt als vanzelfsprekend verondersteld? Welk jargon zou je willen laten uitleggen?"

5. **Action**: "Je geeft alleen om wat de persoon deze week concreet gaat doen. Abstracties, principes, theorieën: niet jouw probleem. Je wil één zin die luidt: 'Maandag doe ik X, met criterium Y, klaar op datum Z.' Als die zin er niet is, schrijf je er één. Als het voorstel geen eerste stap bevat, is het geen plan."

### Stap 3: Anonymiseren

Verzamel de vijf responses. Ken elke response een willekeurige letter A tot E toe via shuffle. Houd de mapping `{lens-naam: letter}` intern bij als lookup-tabel; de orchestrator gebruikt die in Stap 4 om de eigen-letter uit te sluiten per advisor. De responses gaan anoniem naar de volgende fase.

### Stap 4: Blind peer review

Opnieuw vijf parallelle `Agent` calls met `subagent_type: "gurus:sonnet-max"`. Voor elke advisor:

1. Zoek in de mapping uit Stap 3 de letter die aan deze advisor is toegekend. Noem die `OWN`.
2. Stel de vier letters uit `{A, B, C, D, E} \ {OWN}` samen, op volgorde.
3. Geef de advisor de oorspronkelijke brief plus precies deze vier geanonimiseerde responses.
4. De eigen response wordt onder geen enkele letter opgenomen. Dit is de hardste regel van de peer-fase; zonder expliciete exclusie krijgt minstens één advisor zijn eigen werk terug en gaat de anonimiteit verloren.

**Peer review prompt:**

Elke advisor krijgt zijn eigen variant van dit prompt, met zijn eigen letter uit de mapping expliciet genoemd als uitgesloten. Concreet voorbeeld: als Pre-mortem in stap 3 letter C kreeg, staan in het prompt voor Pre-mortem alleen A, B, D en E als reviews. Het prompt vermeldt die mapping inline zodat de orchestrator niet hoeft te vertrouwen op externe state.

```
Je bent advisor [NAAM] uit een board of advisors. Je hebt eerder een eigen review geschreven vanuit je lens, die hieronder niet opgenomen is: jouw letter in de anonieme shuffle was [OWN_LETTER] en die is bewust uitgesloten. Je leest nu de vier overgebleven anonieme reviews en beoordeelt ze.

## De oorspronkelijke situatie

[BRIEF]

## De vier anonieme reviews (jouw eigen letter [OWN_LETTER] is weggelaten)

### Review [LETTER_1]
[INHOUD]

### Review [LETTER_2]
[INHOUD]

### Review [LETTER_3]
[INHOUD]

### Review [LETTER_4]
[INHOUD]

## Wat je doet

Voor elke review beantwoord je drie vragen:

1. **Welke lens denk je dat dit is?** Één woord of korte zin.
2. **Wat is het sterkste punt hierin?** Niet diplomatiek; wat maakt dat deze review iets toevoegt.
3. **Wat is het zwakste punt hierin?** Ook niet diplomatiek; waar valt deze review door de mand.

Daarna: rangschik de vier reviews van meest tot minst waardevol voor de persoon die het advies krijgt. Geef voor je top-1 en je bottom-1 één zin toelichting.

Geen halfslachtige oordelen. Als een review zwak is, zeg dat. Je oordeel is anoniem: de peers weten niet wie jij bent.
```

### Stap 5: Chairman synthese

Eén `Agent` call met `subagent_type: "gurus:sonnet-max"`, rol chairman. Krijgt:

- De oorspronkelijke brief
- Alle vijf originele (niet-anonieme) reviews met lens-naam
- De vijf peer reviews (met rankings)
- De instructie onder

**Chairman prompt:**

```
Je bent chairman van een board of advisors. Vijf advisors hebben deze situatie bekeken vanuit hun eigen lens, en daarna elkaars werk blind beoordeeld. Jouw taak is één verdict dat de persoon kan gebruiken.

## De situatie

[BRIEF]

## De vijf reviews

### Pre-mortem
[INHOUD]

### First-principles
[INHOUD]

### Opportunity-finder
[INHOUD]

### Stranger
[INHOUD]

### Action
[INHOUD]

## De peer reviews

[Vijf peer reviews met hun rankings]

## Wat je levert

### Convergentie
Waar vallen minstens drie van de vijf lenzen samen? Dat is wat de persoon als vaststaand kan behandelen; verdere validatie is hier niet nodig.

### Divergentie
Waar spreken lenzen elkaar expliciet tegen? Welke spanning moet de persoon zelf oplossen, omdat geen enkele lens alleen het antwoord heeft?

### Verdict
Drie tot vijf zinnen. Niet een samenvatting van de reviews; jouw eigen oordeel als chairman na alles gelezen te hebben. Schrijf het zoals je het tegen de persoon zou zeggen wanneer hij binnenloopt om te vragen wat hij hieraan heeft.

### Concrete volgende stap
Eén zin. Wat doet deze persoon maandag? Als geen enkele lens een concrete stap gaf, verzin er een op basis van de convergentie.

Geen diplomatie. Geen "overall good points from everyone". Kies positie.
```

### Stap 6: Presenteer

Presenteer het chairman-verdict prominent, gevolgd door de vijf originele reviews als uitklapbare bronnen. Format:

```
## Council Verdict

### Convergentie
[Uit chairman synthese]

### Divergentie
[Uit chairman synthese]

### Verdict
[Uit chairman synthese]

### Concrete volgende stap
[Uit chairman synthese]

---

<details>
<summary>Pre-mortem</summary>

[Volledige review]

</details>

<details>
<summary>First-principles</summary>

[Volledige review]

</details>

[... etc voor alle vijf]

<details>
<summary>Peer review rangschikking</summary>

Per advisor (bij naam): welke review zij top-1 en bottom-1 kozen (letter en bijbehorende lens-naam uit de mapping), plus de één-zin toelichting per keuze. Geen aggregatie of ranking-score; de individuele oordelen zijn het signaal.

</details>
```

## Regels

- **Vijf agents, niet vier of zes.** De lenzen zijn gekozen voor onderlinge spanning. Afwijken verzwakt het signaal.
- **Geen cross-vendor.** Alle agents draaien op `gurus:sonnet-max`. Geen Gemini, GPT, Grok.
- **Parallel dispatchen waar mogelijk.** Stap 2 en stap 4 zijn elk één message met vijf tool calls. Serieel dispatchen verviervoudigt de latency zonder winst.
- **Anonymisering is verplicht.** Peer review zonder anonymisering wordt hiërarchie-review ("Pre-mortem zegt X, die is altijd goed"). De lens op de response moet verborgen zijn tijdens review.
- **Chairman is geen gemiddelde.** Het verdict mag afwijken van wat de meeste lenzen zeiden wanneer de chairman een sterker argument ziet in een minderheidslens.
- **De persoon beslist, niet het council.** Concrete volgende stap is een voorstel, geen opdracht. De gebruiker zegt "doe het" of "niet dit, liever X".
