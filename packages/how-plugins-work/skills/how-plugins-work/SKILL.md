---
name: how-plugins-work
user-invocable: true
description: Use when diagnosing "Unknown command", slash-command autocomplete misses, or any confusion about how plugin and skill names resolve in Claude Code. Living document explaining plugin naming, skill resolution, and the plugin:skill invocation pattern, based on empirical testing.
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

**Altijd expliciet zetten.** Ondanks dat de binary code (hieronder) suggereert dat de default `true` is, toont de praktijk dat skills zonder expliciete `user-invocable: true` niet altijd in autocomplete verschijnen. Zet het veld altijd expliciet: `true` voor slash commands, `false` voor skills die alleen model-triggered zijn.

Binary code uit Claude Code 2.1.92 (de default `true` werkt niet betrouwbaar voor plugins):
```javascript
T = H["user-invocable"] === void 0 ? !0 : G0H(H["user-invocable"])
```

### disable-model-invocation

Wanneer `true`: het model kan de skill niet automatisch activeren op basis van context. De skill is dan alleen bereikbaar via expliciete slash command. Nuttig voor skills die nooit auto-triggered moeten worden (bijv. `/clipboard`, `/saysay`). Verkleint het actieve context-budget in `skill-budget`.

## Model selectie

Een skill kan het session model NIET veranderen. Het model dat de user koos bij sessie-start (of via `/model`) draait door alle turns heen, inclusief turns die door cron worden gevuurd. Een skill die `/model haiku` als tekst output, gedraagt zich als een nep-user-input, is onbetrouwbaar, en blijft hangen na de skill-run, dus verneukt de user-sessie.

**Subagents wel.** De `Agent`/`Task` tool accepteert een `model` parameter (`haiku`, `sonnet`, `opus`). Een subagent draait in een aparte conversation context met zijn eigen model, returnt een result, en raakt het session model niet aan. Dit is het juiste mechanisme voor:

- Token besparing in cron-driven loops (delegeer poll-werk aan een Sonnet- of Haiku-subagent)
- Parallelle independent taken (meerdere agents op verschillende modellen tegelijk)
- Het session model reserveren voor reasoning, terwijl mechanisch werk goedkoper draait

**Vuistregel:** session model = head, subagent = hand. Geef subagents het werk dat geen interpretatie vereist (commands runnen, files lezen en raw teruggeven, gh-scrapes doen). Houd interpretatie en beslissingen op de session model.

## Symlinks en cross-platform

Symlinks zijn het vehikel waarmee de leclause marketplace skills deelt tussen plugins: `packages/<plugin>/skills/<skill>` verwijst met `../../../skills/<skill>` naar de canonieke source. Officiële Anthropic docs bevestigen dat Claude Code symlinks niet dereferences tijdens install:

> Symlinks are preserved in the cache rather than dereferenced, and they resolve to their target at runtime.

Bron: [Plugins reference, Plugin caching and file resolution](https://code.claude.com/docs/en/plugins-reference).

Op macOS/Linux werkt dit direct. Op Windows breekt het één laag eerder: Git for Windows heeft `core.symlinks=false` als default, dus bij git clone worden symlinks geconverteerd naar text files die het doelpad als inhoud hebben. Wat in de plugin cache belandt is dan geen symlink meer maar een text file, en de runtime resolution faalt.

**`git-subdir` lost dit niet op.** De sparse clone pakt alleen de subdirectory van een plugin mee, en onze symlinks wijzen met `../../../skills/` naar paden buiten de sparse clone. Voor elke consument (macOS, Linux, Windows) levert dat dangling symlinks of text files op.

**`rsync -aL` produceert een gematerialiseerde kopie.** Empirisch getest tegen een lokale marketplace source: `rsync -aL --exclude=.git` van de repo naar een build-directory vervangt elke symlink door de echte directory-inhoud. `claude plugins install` op die build-directory landt in de cache zonder één symlink over. Dit is de structurele aanpak voor Windows-consumers: `main` blijft symlinks gebruiken, een release-branch bevat gematerialiseerde directories, en `marketplace.json` pinnen plugin sources op die branch.

**`CLAUDE_CODE_PLUGIN_SEED_DIR`** is een consumer-side alternatief: een env variable die Claude Code naar een voorgematerialiseerde plugins-directory laat wijzen. Elke consument moet zelf zijn seed dir klaarzetten en bijhouden. Schaalt niet naar meerdere Windows-gebruikers.

Zie `docs/windows-compat-investigation.md` in de leclause-skills repo voor de volledige analyse, inclusief afgewezen alternatieven en de bin-script impact.

## Versioning

De `version` field in `plugin.json` wordt automatisch bijgewerkt door de leclause pre-commit hook. Het format is `1.0.{commits}` waar `{commits}` het aantal commits is dat `packages/<name>/` of `skills/<name>/` heeft geraakt.

## Troubleshooting: "Unknown command: /xyz"

Observed symptom: user types `/rover` (or `/autonomous:rover`) and Claude Code replies `Unknown command`. Diagnose and fix. Do not narrate steps for the user to execute; Claude has shell access and can run the same commands. Dictating install commands is condescending when Claude can just install.

**Step 0 (mandatory, no exceptions).** Run `claude plugins list` yourself before forming any hypothesis. This command is the single source of truth. If the plugin is absent, every theory about prefixing, namespacing, or skill resolution is noise.

1. **Plugin not listed.** Run `claude plugins install <plugin>@<marketplace>`. The Claude process inherits the CLI so this just works. The only thing that is not Claude's to do is the session restart that picks up new plugins: flag that with 🚦 and wait for user go.

2. **Plugin listed but disabled.** Patch `~/.claude/settings.json` `enabledPlugins` to `"<plugin>@<marketplace>": true`. This is a user-level file; ask first before editing.

3. **Marketplace source out of date.** If the plugin only exists on a local branch that the marketplace source (GitHub or local path) has not seen, the install will fail. Fix the source: push the branch (requires user go) or re-point the marketplace at the working copy.

4. **Skill missing `user-invocable: true`.** Without the flag the skill is model-triggered only and no slash command appears. Edit the frontmatter.

5. **Skill name collision across enabled plugins.** Bare `/<skill>` only resolves when unique. Use `/<plugin>:<skill>` via autocomplete.

6. **Stale cache path.** Cached versions live under `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`. A long-running session may point at an older cached skill set. Flag 🚦 for a restart.

Never advise the user to prefix or de-prefix a slash command without having run step 0. "Namespacing is required" is a guess when the actual failure is almost always install state, enable state, or a stale session. And never dictate `claude plugins install ...` at the user; run it.

## Experiment metadata

- Oorspronkelijk experiment: `hpw@leclause` (korte plugin naam, 2026-04-06)
- Hernoemd naar: `how-plugins-work@leclause` (plugin = skill naam, 2026-04-07)
- Claude Code versie: 2.1.92
- Marketplace: leclause (local directory)
