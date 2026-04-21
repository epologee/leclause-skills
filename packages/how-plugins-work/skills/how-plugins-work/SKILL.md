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
| Plugin cache pad | `cache/<marketplace>/<plugin>/<version>/skills/<skill>/` | `cache/leclause/how-plugins-work/<version>/skills/how-plugins-work/` |
| `skill-budget` SOURCE kolom | `<plugin>` | `how-plugins-work` |
| `skill-budget` NAME kolom | `<skill>` | `how-plugins-work` |
| System-reminder skill list | `<plugin>:<skill>` | `how-plugins-work:how-plugins-work` |
| TUI autocomplete | `/<plugin>:<skill>` | `/how-plugins-work:how-plugins-work` |
| Skill tool invocatie | `Skill("<plugin>:<skill>")` of bare `Skill("<skill>")` | `Skill("how-plugins-work")` |
| Slash command (bare) | `/<skill>` (als uniek) | `/how-plugins-work` |
| `claude agents` | `<plugin>:<name> · <model>` | `gurus:sonnet-max · sonnet` |
| Agent tool invocatie | `subagent_type: "<plugin>:<name>"` | `subagent_type: "gurus:sonnet-max"` |
| Plugin-shipped agent source | `packages/<plugin>/agents/<name>.md` | `packages/gurus/agents/sonnet-max.md` |

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

**Effort kan niet per invocatie.** De Agent tool accepteert alleen `model` inline, geen `effort`. De enige route om een subagent op `effort: max` (of welk niveau dan ook) te draaien is via een plugin-shipped of user-level agent definitie met het `effort` frontmatter veld. Zie "Plugin-shipped subagents" hieronder.

## Plugin-shipped subagents

Naast skills kan een plugin ook subagent-definities shippen onder `packages/<plugin>/agents/<name>.md`. Dit is tegelijk de enige manier om een vooraf-geconfigureerde `model` + `effort` combinatie beschikbaar te maken voor runtime spawn, omdat de Agent tool alleen `model` inline accepteert.

### Frontmatter

Ondersteund: `name`, `description`, `model` (`sonnet`/`opus`/`haiku`), `effort` (`low`/`medium`/`high`/`xhigh`/`max`). Voor security redenen genegeerd wanneer de agent uit een plugin komt: `hooks`, `mcpServers`, `permissionMode`. Wie die velden nodig heeft, kopieert de agent definitie naar `~/.claude/agents/` of `.claude/agents/`.

Voorbeeld (empirisch werkend in de leclause marketplace):

```markdown
---
name: sonnet-max
description: Generic subagent pinned to Sonnet at maximum effort.
model: sonnet
effort: max
---

Execute the invoker's prompt and return the result.
```

### Invocatie

Plugin-shipped agents volgen dezelfde `<plugin>:<name>` namespace als skills. Aanroep via de `Agent`/`Task` tool met `subagent_type: "<plugin>:<name>"`. Voor de voorbeeld-agent in `packages/gurus/agents/sonnet-max.md`: `subagent_type: "gurus:sonnet-max"`.

**Bare name werkt NIET.** In tegenstelling tot skills, waar `/how-plugins-work` als bare slash command resolves wanneer uniek, vereist de Agent tool altijd de namespaced vorm voor plugin-shipped agents. Empirische bevestiging in Claude Code 2.1.92: `subagent_type: "sonnet-max"` faalt, `subagent_type: "gurus:sonnet-max"` werkt.

### Verificatie zonder push

Drie trappen, van lichtst naar zwaarst:

1. **`claude agents`.** Toont alle geladen agents in het `<plugin>:<name> · <model>` formaat. Draait tegen de huidige install cache; werkt dus pas na een geslaagde `claude plugin update`.
2. **`claude --plugin-dir ./packages/<plugin> agents`.** Laadt de lokale plugin voor één CLI-sessie zonder de install cache te muteren. Snelst om een wijziging te testen voordat commit/install. Let op: de `--plugin-dir` flag is globaal; `claude agents --plugin-dir X` faalt met `unknown option`, `claude --plugin-dir X agents` werkt.
3. **Live spawn test via `claude -p`.**

   ```bash
   claude -p --allow-dangerously-skip-permissions --output-format json \
     "Use the Task tool with subagent_type '<plugin>:<name>'. Ask for the string PING_42."
   ```

   De JSON output bevat een `modelUsage` sectie met het geconfigureerde model als aparte key (bijv. `claude-sonnet-4-6`). Twee modellen in `modelUsage` (sessie + subagent) is het sterkste bewijs dat de subagent echt gespawnd is met het gewenste model. De `effort` waarde is niet zichtbaar in `modelUsage` of elders in de CLI output; daarvoor rust het op een documentatie-aanname.

### Lokale marketplace voor persistent installeren zonder push

`claude plugin marketplace add ./` (met trailing slash of met expliciet pad) herpuntert een bestaande marketplace alias naar het lokale pad, mits `marketplace.json`'s `name` hetzelfde alias claimt. Concreet: een `marketplace.json` met `"name": "leclause"` in de lokale repo, gecombineerd met een bestaande `leclause` GitHub-marketplace, betekent dat `claude plugin marketplace add ./` de alias silent overschrijft naar de lokale directory. Daarna trekt `claude plugin update <plugin>@leclause` uit de lokale werkkopie in plaats van de remote. Nuttig voor end-to-end testen van plugin wijzigingen zonder eerst te pushen.

**Gotcha:** om terug te vallen op de remote marketplace moet de path-based entry expliciet verwijderd worden met `claude plugin marketplace remove leclause` en opnieuw toegevoegd via de `owner/repo` form.

## Symlinks en cross-platform

De leclause marketplace is symlink-free. Elke skill leeft op één plek onder `packages/<plugin>/skills/<skill>/`, zonder shared-source via symlinks. Pre-commit en CI weigeren symlinks in de repo. De reden is Windows: Git for Windows heeft `core.symlinks=false` als default, dus bij clone worden symlinks omgezet naar text-files met het doelpad als inhoud, en de runtime resolution in Claude Code faalt. Een symlink-vrije layout werkt op macOS, Linux en Windows zonder extra consumer-setup.

Anthropic docs beschrijven wel dat Claude Code symlinks in de install cache bewaart ([Plugins reference, Plugin caching and file resolution](https://code.claude.com/docs/en/plugins-reference)), maar dat vereist dat de symlinks de clone überhaupt overleven. De drie alternatieven die in een eerder experiment zijn verkend (`git-subdir`, `rsync -aL` materialisatie via release branch, `CLAUDE_CODE_PLUGIN_SEED_DIR`) bleken allemaal meer consumer-setup te vereisen dan een vlakke, symlink-vrije layout. De repo is daarop afgestemd.

## Versioning

De `version` field in `plugin.json` wordt automatisch bijgewerkt door de leclause pre-commit hook. Het format is `1.0.{commits}` waar `{commits}` het aantal commits is dat `packages/<name>/` of `skills/<name>/` heeft geraakt.

## Wat landt er in de plugin cache

Claude Code installeert een plugin uit het repo-subpad dat in `marketplace.json` is opgegeven (meestal `packages/<plugin>/`) en dropt de volledige inhoud van dat subpad in de cache. Dat betekent: `.claude-plugin/`, `skills/`, de plugin-level `README.md`, **en** `bin/` landen allemaal mee. Bestanden buiten het subpad (bijvoorbeeld de repo-root `README.md` of de repo-root `bin/`) komen niet mee, want de plugin source start bij `packages/<plugin>/`, niet bij de repo-root.

Empirisch getest tegen `autonomous@leclause` in versie 1.0.23:

```
$HOME/.claude/plugins/cache/leclause/autonomous/1.0.23/
├── .claude-plugin/
│   └── plugin.json
├── README.md            (plugin-level, niet repo-root)
├── bin/
│   └── relative-cron    (consumer-facing helper)
└── skills/
    └── <skill>/...
```

Oudere cache-versies van dezelfde plugin kunnen een andere layout hebben, afhankelijk van wat er in de repo stond op het moment van die installatie. Een cache-inspectie tegen een oude versie bewijst niets over de huidige source-layout; test tegen een fresh `claude plugins update`.

## Het pad naar de actieve install

De authoritative bron voor "welke versie draait nu" is `~/.claude/plugins/installed_plugins.json`:

```bash
jq -r '.plugins["<plugin>@<marketplace>"][0].installPath' ~/.claude/plugins/installed_plugins.json
```

Dat pad is de **plugin-root in de cache**, niet de repo-root. Het bevat `.claude-plugin/`, `skills/`, `bin/` (als de plugin source die heeft) en de plugin-level `README.md`. Concrete pad-templates:

| Target | Correct pad | Fout pad |
|--------|-------------|----------|
| Skill resource | `$installPath/skills/<skill>/<file>` | `$installPath/packages/<plugin>/skills/<skill>/<file>` |
| Bin-script | `$installPath/bin/<script>` | `$installPath/packages/<plugin>/bin/<script>` |
| Plugin manifest | `$installPath/.claude-plugin/plugin.json` | (geen andere) |

De `packages/<plugin>/`-prefix bestaat alleen in de source-repo, niet in de cache. De `ls -1dt ... | head -1` truc tegen `~/.claude/plugins/cache/<marketplace>/<plugin>/` wijst hetzelfde pad aan maar leunt op mtime-ordening en is daardoor niet stabiel; de `jq` lookup werkt deterministisch.

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
- Cache-layout + installPath-verificatie: 2026-04-19 (tegen `autonomous@leclause` 1.0.23)
- Claude Code versie: 2.1.92
- Marketplace: leclause (local directory)
