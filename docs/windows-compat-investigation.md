# Windows-compatibiliteit voor de leclause marketplace

Status: aanbevelingsdocument. Geen code change, dit is de voorbereiding op een implementatie die in een vervolgloop landt.

## Probleemstelling

De leclause-marketplace gebruikt symlinks om skills tussen plugins te delen. Elke `packages/<plugin>/skills/<skill>` verwijst met `../../../skills/<skill>` naar de canonieke source onder de repo-root. Op macOS en Linux werkt dit direct: git bewaart de symlink, Claude Code kopieert de plugin naar zijn cache, en de symlink blijft tijdens runtime werkend.

Op Windows breekt dit in twee stappen. Ten eerste heeft Git for Windows `core.symlinks=false` als default. Zonder die instelling landen symlinks bij clone als text files die het doel-pad als inhoud hebben. Ten tweede, volgens de Anthropic-docs:

> Symlinks are preserved in the cache rather than dereferenced, and they resolve to their target at runtime.

Bron: [Plugins reference, Plugin caching and file resolution](https://code.claude.com/docs/en/plugins-reference).

Claude Code materialiseert symlinks dus niet bij installatie. Het kopieert ze door en probeert ze pas bij runtime te volgen. Op Windows betekent dat: de "symlink" in de cache is een text file, de runtime probeert hem als directory te openen, en de skill faalt. Voor mijn broer, een Windows-gebruiker, is `claude plugins install autonomous@leclause` daarmee stuk zonder verdere handeling.

## Onderzochte alternatieven

Drie aanpakken zijn in het veld terug te vinden, met verschillende kosten en trade-offs.

| Aanpak | Voorbeeld | Wat de consumer moet doen | Bron |
|--------|-----------|---------------------------|------|
| Consumer configureert git | Officiële Anthropic-docs adviseren `git config core.symlinks=true` en herclone. | Developer Mode aanzetten (Windows 10 1703+), git-config zetten, soms admin. Mislukt ook bij achterliggende cache-dereferentie van Claude Code. | [Plugin marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces), [Git for Windows symbolic links](https://gitforwindows.org/symbolic-links.html) |
| POSIX-shell vereiste | garrytan/gstack schrijft expliciet: "gstack works on Windows 11 via Git Bash or WSL." Install via bash install-script dat symlinks lokaal maakt. | Git Bash of WSL installeren. Shell-script runnen. Ook hier: nog steeds Developer Mode of admin nodig voor symlink creation. | [garrytan/gstack README](https://github.com/garrytan/gstack) |
| Materialiseren bij release | Geen publiek voorbeeld in de Claude Code plugin-ecosystem gevonden. Standaardpatroon in JavaScript-monorepos (pnpm, npm workspaces): publish-stap vertaalt interne package-refs naar echte kopieën. | Niks. Consumer ziet een gewone marketplace met echte directories. | Algemene monorepo-patroon; geen specifieke docs-URL in het Claude ecosysteem |

## Aanbeveling: materialise-at-release

De structureel juiste aanpak is optie 3. Symlinks blijven de source-of-truth in de main branch. Een release-stap vertaalt ze naar echte directories in een artefact dat consumers installeren. De macOS-workflow blijft identiek aan vandaag; Windows-consumers krijgen werkende files zonder enige configuratie.

Concreet:

1. **Source-of-truth blijft `main`.** Ik blijf met symlinks werken. `packages/<plugin>/skills/<skill>` verwijst zoals nu naar `skills/<skill>` onder de repo-root. Dual-publishing via het `leclause` bundle-plugin werkt op dezelfde manier.

2. **Nieuwe release branch (`release`) met materialized content.** Een script synct alles van `main` naar `release` en vervangt onderweg elke symlink door de echte directory-inhoud. Kandidaten voor de implementatie: `rsync -aL` gevolgd door een commit op `release`, of `git archive main | tar -x` met een losse symlink-resolving stap, of een build-directory die we force-pushen.

3. **`marketplace.json` wijst naar `release`.** Elke plugin-entry krijgt een expliciete `ref` field in zijn source, bijvoorbeeld `{"source": "github", "repo": "epologee/leclause-skills", "ref": "release"}`. Lokaal adden van de marketplace via een relatieve path blijft werken tegen `main` voor ontwikkelwerk; alleen de publieke install route via github.com haalt `release` op.

4. **Nieuwe script: `bin/marketplace-release`.** Dit is het workhorse. Dry-run modus voor diffen, write-modus voor daadwerkelijk bouwen en force-pushen van `release`. Later eventueel te vervangen door een GitHub Action die bij elke push op `main` de release branch bijwerkt.

5. **Versioning blijft ongewijzigd.** `plugin-versions` werkt op `main` en telt commits per plugin. Omdat `release` een mirror is van `main` met dezelfde commit-geschiedenis effectief platgeslagen of opnieuw gecommit, moet versioning synchroon lopen. Simpelste invulling: `release` commits dragen dezelfde plugin-versies als `main` op dat moment, via `bin/plugin-versions --write` op de release branch.

### Impact

- **`bin/plugin-versions`**: ongewijzigd. Werkt op `main`, gebruikt commit-counts op paths onder `packages/<name>/` en `skills/<name>/`.
- **`bin/plugin-cache-prune`**: ongewijzigd. Operator-only, draait op macOS, schoont lokale cache.
- **`bin/marketplace-release`**: nieuw. Consumer-facing artefact wordt hiermee gebouwd.
- **`marketplace.json`**: elke plugin-entry krijgt een expliciete `ref: release` source.

### Open vragen voor implementatie

Niet in scope van dit onderzoek, wel om op te volgen:

- Update-frequentie van `release`. Per commit op `main`, per tag, of per handmatige run.
- Release-branch met nieuwe commits (handmatig pushen) of met force-push (altijd mirror van `main` state, geen history). Force-push is simpeler; nieuwe commits geeft history.
- Of `release` ook de `.autonomous/`, `docs/`, en andere non-plugin paths moet bevatten. Waarschijnlijk niet; een sparse mirror met alleen `packages/`, `skills/`, `.claude-plugin/`, `README.md` en `LICENSE` is schoner.
- Eventuele GitHub Action als vervolg op het handmatige script.

## Bin-scripts assessment

Drie bash-scripts in de repo, verschillende doelgroepen.

**Operator-only (blijven bash):**

- `bin/plugin-cache-prune`: draait op mijn macOS-machine om stale cache-directories op te schonen. Geen consumer raakt hieraan.
- `bin/plugin-versions`: idem, pre-commit hook en handmatige drift-checks.

Geen port nodig. Deze scripts verlaten mijn machine nooit.

**Consumer-facing (blijft bash, mits Bash tool POSIX-shell gebruikt op Windows):**

- `packages/autonomous/bin/relative-cron`: wordt via de Bash tool aangeroepen door de cron-skill in elke autonomous-loop iteratie. Draait dus op de consumer.

Claude Code's Bash tool gebruikt op Windows Git Bash of WSL als POSIX-shell. Bash-scripts werken daar. Zolang de Bash tool zelf een POSIX-shell op Windows heeft, is geen port nodig. Als er ooit een configuratie is waar de Bash tool een andere shell gebruikt, is een port naar Python of Node de logische vervolgstap. Voor nu: observeer, port alleen als het bewijst nodig te zijn.

## Volgende stap

Aparte loop of implementatie:

1. `bin/marketplace-release` schrijven (dry-run + write modes).
2. Een eerste release-branch bouwen en verifiëren dat een Windows-consumer de plugin kan installeren.
3. `marketplace.json` entries updaten met `ref: release`.
4. Eventueel een GitHub Action voor automatische releases.

Deze loop produceerde alleen de aanbeveling. De implementatie wacht op een aparte `/autonomous:rover` dispatch.
