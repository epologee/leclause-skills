---
name: test-before-push
user-invocable: true
description: De canonieke procedure om wijzigingen in een plugin-marketplace lokaal uit te rollen zodat je er in een andere Claude-sessie mee kan werken zonder eerst naar GitHub te pushen. Triggers op /test-before-push, "test dit lokaal", "test deze branch", "installeer in een andere sessie", "check voor de push".
---

# Test before push

Eén manier, altijd. Geen keuzes, geen opties, geen "optie 1 of optie 2". Wanneer je een marketplace-plugin wilt testen in een nieuwe Claude-sessie voordat je pusht, voer je de procedure hieronder uit precies zoals beschreven.

## Wanneer te gebruiken

- Je hebt lokaal in een marketplace-repo gewerkt (`.claude-plugin/marketplace.json` aanwezig in root)
- Je wilt dat de nieuwe versie in een nieuwe Claude-sessie buiten deze repo laadbaar is
- Pushen is nog niet aan de orde; dit is de pre-push test

Niet gebruiken wanneer de repo geen marketplace is. Niet gebruiken voor user-level skills in `~/.claude/skills/` (die laden sowieso direct).

## Precondities

Draai deze checks als één bash-blok en bevestig elke regel voordat je door gaat:

```bash
[ -f .claude-plugin/marketplace.json ] \
  && jq -r '.name' .claude-plugin/marketplace.json \
  && git status --short
```

Eerste regel: marketplace.json moet bestaan in de repo-root. Tweede regel: lees de alias uit marketplace.json (bijv. `leclause`, `stekker`); die alias wordt silent overschreven door stap 1 hieronder. Derde regel: werktree schoon, of commits landen in deze installatie.

## De procedure (stap 1, push-vorm)

```bash
claude plugins marketplace add ./
```

Dat herpuntert de alias (uit marketplace.json) naar de huidige working copy. Daarna, voor elk plugin dat je in deze sessie hebt gewijzigd:

```bash
claude plugins update <plugin>@<alias>
```

`<alias>` is wat marketplace.json als `name` heeft. `<plugin>` is de plugin-directory in `packages/`. De update pulls uit de lokale werkkopie, niet uit GitHub. Caching pad: `~/.claude/plugins/cache/<alias>/<plugin>/<version>/`.

Bevestig succes met:

```bash
jq '.plugins["<plugin>@<alias>"][0].version' ~/.claude/plugins/installed_plugins.json
```

Die versie moet matchen met de `version` in `packages/<plugin>/.claude-plugin/plugin.json`.

## In een nieuwe Claude-sessie

Open een nieuwe Claude Code sessie in een willekeurige directory (hoeft niet deze repo). Het plugin is globaal beschikbaar via de user-scope install. Typ de slash-command van de plugin (bijvoorbeeld `/gurus:software` voor de gurus-plugin) en test het gedrag.

De huidige sessie waarin je dit uitvoert, draait al met de oude versie geladen in-memory. Die zie je pas updaten na een herstart van deze sessie. Voor de test ga je naar een verse sessie.

## De revert (stap 2, na testen)

Wanneer je klaar bent met testen en klaar om daadwerkelijk te pushen, zet de alias terug naar de GitHub-source:

```bash
OWNER_REPO=$(git remote get-url origin | sed -E 's#.*github.com[:/](.+)/(.+)(\.git)?$#\1/\2#; s#\.git$##')
claude plugins marketplace add "$OWNER_REPO"
claude plugins update <plugin>@<alias>
```

Dat trekt de alias weer naar GitHub en laadt de geïnstalleerde plugin van daar (zodra je gepusht hebt en de marketplace.json van main vers is).

## Waarom deze procedure en geen andere

Andere paden die verleidelijk lijken maar vermeden worden:

1. **`claude plugins marketplace remove <alias>`** voordat je opnieuw toevoegt. Dat cascade-uninstalleert elke plugin onder die alias (empirisch: 18 plugins tegelijk kwijt). Zie how-plugins-work SKILL.md "Gotcha 1".
2. **Handmatig de plugin cache kopiëren**. Werkt technisch maar drift tussen `installed_plugins.json` en de cache is onzichtbaar en breekt volgende updates.
3. **Tijdelijke branch pushen**. Dat is wat we juist willen vermijden totdat de test gedaan is.

De `marketplace add ./` aanpak is silent alias-overwrite en vereist geen remove, dus geen cascade. Dat is de enige reden deze procedure bestaat: hij doet het zonder plugins te verliezen.

## Blokkeringen en hoe ermee om te gaan

**`block-bad-paths` op absolute paden.** Werk met `./` of `.` vanaf de repo-root, niet met een absolute `/Users/.../` pad. De user-level hook `block-bad-paths.sh` weigert absolute home-paden. `./` wordt door `claude plugins marketplace add` intern naar een absolute pad gemapt en opgeslagen, dus je hoeft zelf geen absolute string in te typen.

**`version` veld in plugin.json komt niet overeen.** De leclause pre-commit hook bumpt automatisch bij commit. Als je niet gecommit hebt sinds een edit, staat de version een commit achter op wat de cache krijgt. Commit eerst, update daarna.

## Contract

Deze skill heeft geen bevestigings-stap. Geen "optie 1 of optie 2", geen "akkoord?". De enige vraag die voor de procedure mag komen is de precondities-check. Zodra die groen is, wordt de procedure uitgevoerd.
