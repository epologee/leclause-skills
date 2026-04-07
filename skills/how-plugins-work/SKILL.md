---
name: how-plugins-work
description: Explains how Claude Code plugin naming, skill resolution, and the plugin:skill invocation pattern work in practice. Living document based on empirical testing.
---

# How Plugins Work

Een levend document over hoe Claude Code plugin- en skill-namen door het systeem stromen. Gebaseerd op empirisch testen met de leclause marketplace in Claude Code 2.1.92.

## De drie namen

Een skill in een marketplace-plugin heeft drie onafhankelijke namen:

1. **Plugin name** (`plugin.json` > `name`): bepaalt de namespace.
2. **Skill name** (directory naam onder `skills/`): bepaalt de identiteit.
3. **Marketplace name** (marketplace.json > `name` of de `@marketplace` identifier): bepaalt de bron.

Deze drie namen zijn volledig onafhankelijk van elkaar. Claude Code combineert ze op verschillende manieren op verschillende plekken.

## Waar verschijnt wat (empirisch geverifieerd)

| Context | Wat verschijnt | Voorbeeld |
|---------|----------------|-----------|
| `claude plugin list` | `<plugin>@<marketplace>` | `how-plugins-work@leclause` |
| `claude plugin install` | `<plugin>@<marketplace>` | `claude plugin install how-plugins-work@leclause` |
| `settings.json` enabledPlugins | `"<plugin>@<marketplace>": true` | `"how-plugins-work@leclause": true` |
| `installed_plugins.json` key | `"<plugin>@<marketplace>"` | `"how-plugins-work@leclause": [...]` |
| Plugin cache pad | `cache/<marketplace>/<plugin>/<version>/skills/<skill>/` | `cache/leclause/how-plugins-work/1.0.2/skills/how-plugins-work/` |
| `skill-budget` SOURCE kolom | `<plugin>` | `how-plugins-work` |
| `skill-budget` NAME kolom | `<skill>` | `how-plugins-work` |
| System-reminder skill list | `<plugin>:<skill>` | `how-plugins-work:how-plugins-work` |
| TUI autocomplete | `/<plugin>:<skill>` | `/how-plugins-work:how-plugins-work` |
| Skill tool invocatie | `Skill("<plugin>:<skill>")` of bare `Skill("<skill>")` | `Skill("how-plugins-work")` |
| Slash command (bare) | `/<skill>` (als uniek) | `/how-plugins-work` |

### Observaties

**Plugin name verschijnt in vijf contexten:** plugin list, settings.json, installed_plugins.json, skill-budget SOURCE, en als namespace-prefix in system-reminders en autocomplete.

**Skill name verschijnt in drie contexten:** skill-budget NAME, als suffix na de dubbele punt in system-reminders, en als bare slash command.

**Marketplace name verschijnt in twee contexten:** achter het `@` teken in plugin list en settings.json. Nooit in de skill-invocatie zelf.

**De `<plugin>:<skill>` combinatie** is hoe het model de skill ziet in system-reminders en hoe het de Skill tool aanroept. Wanneer plugin en skill dezelfde naam hebben, krijg je `how-plugins-work:how-plugins-work`. De bare shortcut `/how-plugins-work` werkt als er geen naamconflicten zijn.

## Uniqueness en conflicten

### Binnen een marketplace

De unieke sleutel is `<plugin.json name>@<marketplace>`. De plugin name komt uit `plugin.json`, niet uit de directory naam. Als twee packages dezelfde `name` in hun `plugin.json` hebben, claimen ze dezelfde sleutel en overschrijven ze elkaar bij installatie.

Twee **verschillende plugins** in dezelfde marketplace mogen wel een skill met dezelfde naam bevatten. Ze worden genamespaced: `pluginA:review` vs `pluginB:review`. Maar bare `/review` wordt dan ambigu.

### Tussen marketplaces

`superpowers@claude-plugins-official` en `superpowers@leclause` kunnen naast elkaar bestaan (verschillende sleutels). Maar `Skill("superpowers:brainstorming")` bevat geen marketplace, dus als beide een `brainstorming` skill hebben, is de resolutie onvoorspelbaar. Vermijd plugin-namen die al bestaan in andere geinstalleerde marketplaces.

## Dual-publishing: individueel en gebundeld

Een skill kan in twee plugins tegelijk voorkomen: individueel (`ship-it@leclause`) en als onderdeel van een bundel (`leclause@leclause`). Beide symlinken naar dezelfde `skills/ship-it/SKILL.md` source.

```
packages/ship-it/skills/ship-it      -> skills/ship-it   (individueel)
packages/leclause/skills/ship-it     -> skills/ship-it   (bundel)
```

**Beide mogen tegelijk enabled zijn.** Hoewel de system-reminder de skill dan dubbel toont (`ship-it:ship-it` en `leclause:ship-it`), is er geen functioneel conflict: de content is identiek omdat beide symlinken naar hetzelfde bronbestand. Claude Code pikt er een, het maakt niet uit welke.

**De enige kosten zijn context-budget.** `skill-budget` telt de skill dubbel (CRUFT sectie detecteert dit). Oplossing: geef de individuele variant `disable-model-invocation: true` en houd de bundel actief, of andersom. Dan betaal je geen dubbele context-kosten maar behoud je de installatie-flexibiliteit.

### Gebruiksscenario

| Gebruiker | Installeert | Invocatie | Enable/disable |
|-----------|-------------|-----------|----------------|
| Poweruser | Individuele plugins | `/ship-it` (bare) | Per skill via enabledPlugins |
| Nieuwe gebruiker | `leclause@leclause` bundel | `/leclause:ship-it` | Alles-of-niets |

### Operationele kosten

- De bundel-plugin bumpt bij elke wijziging aan elke skill
- `packages/leclause/skills/` heeft een symlink per skill
- Elke nieuwe skill vereist een symlink in de bundel EN een nieuw individueel package
- De pre-commit hook moet de bundel-versie bumpen bij elke skill-wijziging

## SKILL.md frontmatter

### name

Optioneel. Wanneer aanwezig, moet deze matchen met de directory naam. Als ze niet matchen, zijn er gedocumenteerde bugs: het model kan de skill niet vinden bij invocatie (anthropics/claude-code#22063). De directory naam is altijd de bron van waarheid.

### user-invocable

**Defaultt naar `true` wanneer niet opgegeven.** Elke skill is automatisch een slash command. De flag is alleen nuttig als `user-invocable: false` om een skill expliciet uit autocomplete te halen. `user-invocable: true` toevoegen is een no-op.

Geverifieerd in de Claude Code 2.1.92 binary:
```javascript
T = H["user-invocable"] === void 0 ? !0 : G0H(H["user-invocable"])
```

### disable-model-invocation

Wanneer `true`: het model kan de skill niet automatisch activeren op basis van context. De skill is dan alleen bereikbaar via expliciete slash command. Nuttig voor skills die nooit auto-triggered moeten worden (bijv. `/clipboard`, `/saysay`). Verkleint het actieve context-budget in `skill-budget`.

## Versioning

De `version` field in `plugin.json` wordt automatisch bijgewerkt door de leclause pre-commit hook. Het format is `1.0.{commits}` waar `{commits}` het aantal commits is dat `packages/<name>/` of `skills/<name>/` heeft geraakt.

## Experiment metadata

- Oorspronkelijk experiment: `hpw@leclause` (korte plugin naam, 2026-04-06)
- Hernoemd naar: `how-plugins-work@leclause` (plugin = skill naam, 2026-04-07)
- Claude Code versie: 2.1.92
- Marketplace: leclause (local directory)
