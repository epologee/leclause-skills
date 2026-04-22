---
name: whywhy
user-invocable: true
description: Use when the user types /whywhy with a question or goal to drill N layers deep autonomously (default 7). Claude asks and answers "why?" itself, then analyzes the chain for a better direction toward the goal.
args: "[aantal] <vraag, doel, of stelling>"
---

# Why

Stel N keer "waarom?" aan jezelf en beantwoord elke laag zelf. Analyseer daarna de keten voor een richting die het oorspronkelijke doel beter benadert. Gebaseerd op Toyota's 5 Whys, standaard uitgebreid naar 7 lagen.

## Argumenten

`/whywhy [aantal] <vraag>`

- Als het eerste token een puur geheel getal is (bv. `10`), gebruik dat als aantal lagen en de rest als stelling.
- Anders: default naar 7 lagen en gebruik de volledige input als stelling.
- Minimum 3 lagen, maximum 20. Buiten dat bereik: clamp naar de grens en benoem het kort voordat je begint.

Voorbeelden:
- `/whywhy werkt dit nog?` → 7 lagen
- `/whywhy 10 werkt dit nog?` → 10 lagen
- `/whywhy 5 waarom is deze PR zo groot?` → 5 lagen

## Wanneer

- Een beslissing voelt onhelder of ongemotiveerd
- Het doel is vaag en heeft scherpte nodig
- Root cause analyse van een probleem
- Self-improvement: waarom werkt iets niet zoals gewenst
- De user wil begrijpen wat er echt onder een vraag zit

## Workflow

### 1. Formuleer laag 0

Neem de vraag, het doel, of de stelling die de user meegeeft als laag 0.

### 2. Doorloop N lagen

Stel jezelf een scherpe "waarom?" en beantwoord die. Bouw elke volgende vraag voort op het vorige antwoord.

**Slechte waarom:** "Waarom?" (kaal, lui)
**Goede waarom:** "Waarom is die snelheid belangrijker dan de structurele kwaliteit?" (specifiek, confronterend)

De vragen mogen ongemakkelijk zijn. Het doel is diepte, niet comfort. Rationaliseer niet. Als een antwoord een ongemakkelijke waarheid bevat, benoem die in plaats van eromheen te praten.

**Bronnen gebruiken.** De antwoorden mogen niet puur uit modelgewichten komen wanneer ze verifieerbaar zijn. Gebruik Grep, Read, WebSearch waar relevant. Een "waarom werkt onze deploy zo traag?" verdient een blik in de codebase, niet alleen redenering.

### 3. Toon de keten

Vervang `N` door het daadwerkelijke aantal lagen in de heading en in de laatste laag.

```
## Nx Why: [oorspronkelijke stelling]

**0.** [stelling]
**1.** Waarom [vraag]?
   [antwoord]
**2.** Waarom [vraag]?
   [antwoord]
...
**N.** Waarom [vraag]?
   [antwoord]
```

### 4. Analyseer

Zoek patronen in de keten:

| Patroon | Betekenis |
|---------|-----------|
| Convergentie | Meerdere lagen wijzen naar hetzelfde thema. Dat is de kern. |
| Breukpunt | Een laag waar het antwoord van richting verandert. Daar zit een onuitgesproken aanname. |
| Cirkel | Een antwoord herhaalt een eerdere laag. De cirkel zelf is het inzicht. |
| Verdieping | Elk antwoord gaat een laag dieper. De laatste laag is het meest waardevol. |

### 5. Herkadering en richting

Formuleer:
1. **Wat opvalt** in de keten (patronen, breukpunten)
2. **Herkadering** van het oorspronkelijke doel vanuit de diepste laag
3. **Vervolgrichting**: een concrete suggestie om het doel beter te benaderen

De richting is een voorstel, geen conclusie. De user beslist.

## Regels

- **Eerlijk boven comfortabel.** Een waarom-keten die alleen bevestigt wat je al dacht is waardeloos.
- **Specifiek boven abstract.** "Omdat het beter is" is geen antwoord. Beter hoe? Voor wie? Waarom?
- **Geen herhaling.** Als een antwoord op laag 5 lijkt op laag 3, benoem de cirkel en breek erdoorheen.
- **Kort per laag.** Elk antwoord maximaal 2-3 zinnen. De kracht zit in de keten, niet in de individuele antwoorden.
