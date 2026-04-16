---
name: export-skill
user-invocable: true
description: Use when the user wants to export/share a skill with others. Thin orchestrator that chains sanitize-skill, optional translate-skill or port-skill, package-skill, and share-skill. For partial workflows, invoke the sub-skills directly.
argument-hint: "<skill-name> [en|nl|linux|windows]"
---

# Export Skill

Exporteer een skill uit `~/.claude/skills/` als gesanitiseerd en verpakt bestand, klaar om te delen. Deze skill is een dunne orchestrator: hij delegeert het echte werk naar de sub-skills via het Skill-tool.

## Invocatie

```
/export-skill say              # sanitiseer + verpak + handoff
/export-skill say en           # sanitiseer + vertaal naar Engels + verpak + handoff
/export-skill say nl           # sanitiseer + vertaal naar Nederlands + verpak + handoff
/export-skill say linux        # sanitiseer + port naar Linux + verpak + handoff
/export-skill say windows      # sanitiseer + port naar Windows + verpak + handoff
```

Eerste argument: naam van een skill-directory in `~/.claude/skills/`.
Tweede argument (optioneel): doeltaal (`en`/`nl`) of doelplatform (`linux`/`windows`).

## Orchestratie

De chain is elke stap een Skill-tool invocatie van een sub-skill. Niks inline, geen rules in dit bestand.

1. **Sanitiseer** via `sanitize-skill`:
   - Input: skill-naam (argument 1)
   - Output: `/tmp/skill-exports/<naam>/`

2. **Transformeer** (optioneel, als tweede argument aanwezig):
   - `en` of `nl` -> `translate-skill` met input `/tmp/skill-exports/<naam>/` en doeltaal
   - `linux`, `windows`, of `macos` -> `port-skill` met input `/tmp/skill-exports/<naam>/` en doelplatform
   - Output: `/tmp/skill-exports/<naam>-<suffix>/`

3. **Verpak** via `package-skill`:
   - Input: de output van de vorige stap (gesanitiseerde of getransformeerde directory)
   - Output: `/tmp/skill-exports/<naam>[-<suffix>].zip` of `<naam>[-<suffix>]-SKILL.md`

4. **Handoff** via `share-skill`:
   - Input: het zojuist verpakte bestand
   - Zet samenvatting klaar voor `/clipboard`, opent Finder, print rapport

Als een stap faalt, stop de chain en rapporteer de fout duidelijk. Ga niet door met de volgende stap als de vorige output niet bestaat.

## Standalone gebruik

Elke sub-skill is ook zelfstandig user-invocable. Gebruik de sub-skills direct als je maar een deel van de workflow wilt:

- `/export-skill:sanitize-skill` om alleen PII te strippen zonder verpakken.
- `/export-skill:translate-skill` om een skill te vertalen zonder hem te delen.
- `/export-skill:port-skill` om een skill naar een ander platform te porten voor eigen gebruik.
- `/export-skill:package-skill` om een willekeurige directory te zippen.
- `/export-skill:share-skill` om een bestaand bestand naar Finder + clipboard te brengen.

De orchestrator is een gemak voor de meest voorkomende flow: "ik wil deze skill met iemand delen."

## Backwards-compat notitie

Deze orchestrator behoudt exact dezelfde user-facing invocatie als de originele `export-skill`. Het tweede argument blijft werken voor taal en platform. De interne structuur is veranderd (delegatie naar sub-skills), maar de user merkt daar niks van behalve dat de skill nu ook in kleinere brokken bruikbaar is.

## Foutafhandeling

- Als `<naam>` niet bestaat als directory in `~/.claude/skills/`, vangt `sanitize-skill` dit en meldt. Orchestrator stopt.
- Als het tweede argument iets anders is dan `en`, `nl`, `linux`, `windows`, `macos`, meld dit en stop voor de transformatie-stap begint.
- Als de doellocatie voor een van de stappen al bestaat, vangt de betreffende sub-skill dit. Orchestrator stopt en wijst de user op de conflict.
