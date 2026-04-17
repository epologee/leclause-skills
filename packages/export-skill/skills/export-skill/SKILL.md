---
name: export-skill
user-invocable: true
description: Use when the user wants to export/share a skill with others. Thin orchestrator that chains sanitize, optional translate or port, package, and share. For partial workflows, invoke the sub-skills directly.
argument-hint: "<skill-name> [en|nl|linux|windows|macos]"
allowed-tools:
  - Skill
  - Bash(ls *)
---

# Export Skill

Exporteer een skill uit `~/.claude/skills/` als gesanitiseerd en verpakt bestand, klaar om te delen. Deze skill is een dunne orchestrator: elk nummer hieronder is exact een Skill-tool invocatie. Geen inline regels, geen eigen PII-matrix of platform-matrix: die leven in de sub-skills.

## Invocatie

```
/export-skill say              # sanitiseer + verpak + handoff
/export-skill say en           # sanitiseer + vertaal naar Engels + verpak + handoff
/export-skill say nl           # sanitiseer + vertaal naar Nederlands + verpak + handoff
/export-skill say linux        # sanitiseer + port naar Linux + verpak + handoff
/export-skill say windows      # sanitiseer + port naar Windows + verpak + handoff
```

Eerste argument: `{{NAME}}` = naam van een skill-directory in `~/.claude/skills/`.
Tweede argument (optioneel): `{{SUFFIX}}` = doeltaal (`en`/`nl`) of doelplatform (`linux`/`windows`/`macos`).

## Orchestratie

Elke stap is een `Skill` tool invocatie. De output van stap N is de input van stap N+1. Bij elke stap houd je de `CURRENT_PATH` variabele bij; die begint leeg en wordt na elke stap ingevuld met het pad dat de sub-skill produceerde.

### Stap 1. Sanitiseren (altijd)

```
Skill(skill="export-skill:sanitize", args="{{NAME}}")
```

Verwachte output: directory `/tmp/skill-exports/{{NAME}}/`. Zet `CURRENT_PATH = /tmp/skill-exports/{{NAME}}/`.

### Stap 2. Transformeren (alleen als `{{SUFFIX}}` gegeven)

Bij taal (`en`/`nl`):

```
Skill(skill="export-skill:translate", args="{{CURRENT_PATH}} {{SUFFIX}}")
```

Bij platform (`linux`/`windows`/`macos`):

```
Skill(skill="export-skill:port", args="{{CURRENT_PATH}} {{SUFFIX}}")
```

Verwachte output: directory `/tmp/skill-exports/{{NAME}}-{{SUFFIX}}/`. Zet `CURRENT_PATH = /tmp/skill-exports/{{NAME}}-{{SUFFIX}}/`.

Sla stap 2 over als er geen tweede argument is.

### Stap 3. Verpakken

```
Skill(skill="export-skill:package", args="{{CURRENT_PATH}}")
```

Verwachte output: bestand `{{CURRENT_PATH%/}}.zip` of `{{CURRENT_PATH%/}}-SKILL.md` (afhankelijk van het aantal tekstbestanden in de directory). Zet `CURRENT_PATH` naar het nieuwe pad.

### Stap 4. Handoff

```
Skill(skill="export-skill:share", args="{{CURRENT_PATH}}")
```

share leest de bron-SKILL.md (uit een directory of een los `-SKILL.md` bestand), opent Finder op de parent, en eindigt met een samenvatting als laatste antwoord zodat `/clipboard` die kopieert.

Wanneer de input een `.zip` is, wijs `share` naar de oorspronkelijke directory (voor stap 3) of naar het single-file `-SKILL.md` alternatief. Zip-bestanden leest share niet.

### Foutafhandeling

Als een Skill-invocatie faalt of de verwachte output niet produceert, stop de chain en rapporteer de fout inclusief welke stap faalde en welk pad ontbrak. Spring niet naar de volgende stap.

## Standalone gebruik

Elke sub-skill is ook zelfstandig user-invocable. Gebruik de sub-skills direct als je maar een deel van de workflow wilt:

- `/export-skill:sanitize <naam>` om alleen PII te strippen.
- `/export-skill:translate <pad> <en|nl>` om te vertalen.
- `/export-skill:port <pad> <linux|windows|macos>` om te porten.
- `/export-skill:package <pad>` om een willekeurige directory te zippen of als single-file md te emitten.
- `/export-skill:share <pad>` om samenvatting + Finder handoff te doen op een bestaande export.

De orchestrator is een gemak voor de meest voorkomende flow: "ik wil deze skill met iemand delen."

### Veelvoorkomende combinaties

- **Port voor eigen gebruik** (niet delen, geen Finder): `/export-skill:port <naam> linux`. Schrijft naar `~/.claude/skills/<naam>-linux/`, geen `/tmp/skill-exports/`, geen package, geen Finder.
- **Vertaal EN port**: de orchestrator doet maar een transformatie tegelijk. Voor de combinatie chain je handmatig: `sanitize` -> `translate` -> `port` -> `package` -> `share`.
- **Alleen repackagen** (bestaande geexporteerde dir opnieuw inpakken): `/export-skill:package /tmp/skill-exports/<naam>/`.

## Validatie vooraf

- `{{NAME}}` moet corresponderen met een bestaande directory in `~/.claude/skills/`. Check met `ls ~/.claude/skills/{{NAME}}/`. Als hij niet bestaat, stop voor stap 1.
- `{{SUFFIX}}` moet (als aanwezig) een van `en`, `nl`, `linux`, `windows`, `macos` zijn. Anders stop met een fout voor stap 2.
- Als `/tmp/skill-exports/{{NAME}}/` al bestaat, stop met een duidelijke melding zodat de user handmatig kan opruimen.
