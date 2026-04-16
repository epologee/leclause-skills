# Windows-compatibiliteit voor de leclause marketplace

Status: aanbevelingsdocument. Geen code change, dit is de voorbereiding op een implementatie die in een vervolgloop landt.

## Probleemstelling

De leclause-marketplace gebruikt symlinks om skills tussen plugins te delen. Elke `packages/<plugin>/skills/<skill>` verwijst met `../../../skills/<skill>` naar de canonieke source onder de repo-root. Op macOS en Linux werkt dit direct: git bewaart de symlink bij clone, Claude Code kopieert de plugin naar zijn cache zonder te dereferencen, en de symlink blijft tijdens runtime werkend.

Op Windows breekt dit al bij de git-clone-stap. Git for Windows heeft `core.symlinks=false` als default. Zonder die instelling worden symlinks bij clone geconverteerd naar text files die het doel-pad als inhoud hebben. Wat Claude Code vervolgens naar zijn cache kopieert is dus geen symlink meer, maar een text file. Bij runtime probeert Claude Code de "skill directory" te openen, krijgt een file terug in plaats van een directory, en de skill faalt.

De Anthropic-docs bevestigen dat symlinks op zich wel ondersteund zijn:

> Symlinks are preserved in the cache rather than dereferenced, and they resolve to their target at runtime.

Bron: [Plugins reference, Plugin caching and file resolution](https://code.claude.com/docs/en/plugins-reference). Let op: die passage beschrijft absolute symlinks als workaround voor het pad-traversal-verbod binnen de cache. De mechanische implicatie, "geen dereferentie bij install", is ook van toepassing op onze relatieve symlinks, maar het probleem op Windows zit één laag eerder: de symlink bereikt de cache nooit als symlink.

Voor mijn broer, een Windows-gebruiker, is `claude plugins install autonomous@leclause` daarmee stuk zonder verdere handeling.

## Onderzochte alternatieven

Vier aanpakken zijn in het veld terug te vinden of uit de Claude-docs af te leiden, met verschillende kosten en trade-offs.

| # | Aanpak | Voorbeeld | Wat de consumer moet doen | Bron |
|---|--------|-----------|---------------------------|------|
| 1 | Consumer configureert git | `git config core.symlinks=true` plus Developer Mode of admin. | Developer Mode aanzetten (Windows 10 1703+), git-config zetten, soms admin. | [Git for Windows symbolic links](https://gitforwindows.org/symbolic-links.html) |
| 2 | POSIX-shell vereiste | garrytan/gstack schrijft expliciet: "gstack works on Windows 11 via Git Bash or WSL." Install via bash install-script dat symlinks lokaal maakt. | Git Bash of WSL installeren. Shell-script runnen. Ook hier: nog steeds Developer Mode of admin nodig voor symlink creation. | [garrytan/gstack README](https://github.com/garrytan/gstack) |
| 3 | `git-subdir` source per plugin | De Anthropic-docs documenteren `git-subdir` als sparse clone van een subdirectory in een monorepo. Per plugin-entry in `marketplace.json` zou je kunnen wijzen naar `packages/<plugin>` in onze repo. | Niks. Consumer krijgt een sparse clone van alleen die subdirectory. | [Plugin marketplaces docs, git-subdir](https://code.claude.com/docs/en/plugin-marketplaces) |
| 4 | Materialiseren bij release | Geen publiek voorbeeld in de Claude Code plugin-ecosystem gevonden. Standaardpatroon in JavaScript-monorepos (pnpm, npm workspaces): publish-stap vertaalt interne package-refs naar echte kopieën. | Niks. Consumer ziet een gewone marketplace met echte directories. | Algemene monorepo-patroon; geen specifieke docs-URL in het Claude ecosysteem |

### Waarom `git-subdir` niet voldoet

Aantrekkelijk op het eerste gezicht: Anthropic-geïndorste source-type, sparse clone, geen extra infrastructuur. Maar de sparse clone van `packages/<plugin>` pakt alleen die subdirectory mee. De symlinks daarin wijzen met `../../../skills/<skill>` naar paden buiten de sparse clone. Op macOS/Linux blijft dat een symlink naar een pad dat niet bestaat in de checkout. Op Windows blijft de symlink een text file. Beide gevallen zijn stuk.

Om `git-subdir` wel te laten werken zou ik de source moeten herstructureren: elk `packages/<plugin>` moet een zelfstandige directory zijn zonder symlinks naar buiten. Dat is effectief hetzelfde als materialiseren aan de bron, alleen dan permanent in `main`. Dat offert het shared-skill-pattern op dat dual-publishing (individueel plus `leclause` bundle) mogelijk maakt. Trade-off te groot; niet de gewenste richting.

### Kort afgeschreven: CLAUDE_CODE_PLUGIN_SEED_DIR en npm

Twee alternatieven die bovenkomen bij diepere research maar niet in de hoofdtabel horen.

`CLAUDE_CODE_PLUGIN_SEED_DIR` is een environment variable die Claude Code naar een voorgematerialiseerde plugins-directory laat wijzen. Dit is een consumer-side workaround, valt in dezelfde categorie als optie 1: de consumer moet zelf iets configureren en een resolved kopie van de repo klaarzetten (bijvoorbeeld via `cp -rL`). Past niet bij de eis "consumer hoeft niks te doen." Niet gekozen.

Npm distribution is een echt alternatief. Elke plugin publiceren als npm package met een post-install script dat materialized files naar de plugin cache schrijft. Symlinks spelen geen rol meer. Nadelen: npm-account nodig, publish-workflow, versie-drift tussen npm en GitHub. De marketplace-entries zouden `source: npm` gebruiken in plaats van `source: github`. Te ver buiten de huidige architectuur, en voegt een tweede publicatiekanaal toe zonder sterk voordeel boven materialise-at-release. Niet gekozen.

## Aanbeveling: materialise-at-release

De structureel juiste aanpak is optie 4. Symlinks blijven de source-of-truth in de main branch. Een release-stap vertaalt ze naar echte directories in een artefact dat consumers installeren. De macOS-workflow blijft identiek aan vandaag; Windows-consumers krijgen werkende files zonder enige configuratie.

Concreet:

1. **Source-of-truth blijft `main`.** Ik blijf met symlinks werken. `packages/<plugin>/skills/<skill>` verwijst zoals nu naar `skills/<skill>` onder de repo-root. Dual-publishing via het `leclause` bundle-plugin werkt op dezelfde manier.

2. **Nieuwe release branch (`release`) met materialized content.** Een script synct alles van `main` naar `release` en vervangt onderweg elke symlink door de echte directory-inhoud. Kandidaten voor de implementatie: `rsync -aL` gevolgd door een commit op `release`, of `git archive main | tar -x` met een losse symlink-resolving stap, of een build-directory die we force-pushen.

3. **`marketplace.json` wijst naar `release`.** Elke plugin-entry krijgt een expliciete `ref` field in zijn source, bijvoorbeeld `{"source": "github", "repo": "epologee/leclause-skills", "ref": "release"}`. Lokaal adden van de marketplace via een relatieve path blijft werken tegen `main` voor ontwikkelwerk; alleen de publieke install route via github.com haalt `release` op.

4. **Nieuwe script: `bin/marketplace-release`.** Dit is het workhorse. Dry-run modus voor diffen, write-modus voor daadwerkelijk bouwen en force-pushen van `release`. Later eventueel te vervangen door een GitHub Action die bij elke push op `main` de release branch bijwerkt.

5. **Versioning koppelt main aan release.** `plugin-versions` telt commits per plugin op de branch waar het draait. Als `release` wordt force-pushed met één mirror-commit, zou het tool op die branch overal "1.0.1" rapporteren. Oplossing: `plugin-versions --write` draait altijd op `main`, het resultaat wordt in de plugin.json files van de release-build geschreven, en die files gaan mee in de force-push. Het tool zelf verandert niet; de release-script roept het aan op main, leest de versies, en commit ze naar release. Dit is niet optioneel: Claude Code detecteert updates via `plugin.json` version, dus release moet de correcte versies van main dragen of consumers missen nooit een update.

### Impact

- **`bin/plugin-versions`**: zelf ongewijzigd, maar de aanroep-context wijzigt. Moet op `main` draaien; het resultaat landt via het release-script in de plugin.json files van de release-build.
- **`bin/plugin-cache-prune`**: ongewijzigd. Operator-only, draait op macOS, schoont lokale cache.
- **`bin/marketplace-release`**: nieuw. Consumer-facing artefact wordt hiermee gebouwd. Force-push model: draait plugin-versions op main, rsync -aL van `main` naar een build-directory (resolveert symlinks naar echte directories), schrijft plugin.json versies, force-pusht naar `release`.
- **`marketplace.json`**: elke plugin-entry krijgt een expliciete `ref: release` source.

### Open vragen voor implementatie

Niet in scope van dit onderzoek, wel om op te volgen:

- Update-frequentie van `release`. Per commit op `main`, per tag, of per handmatige run.
- Of `release` ook de `.autonomous/`, `docs/`, en andere non-plugin paths moet bevatten. Waarschijnlijk niet; een sparse mirror met alleen `packages/`, `skills/`, `.claude-plugin/`, `README.md` en `LICENSE` is schoner.
- Consumenten die `release` lokaal hebben uitgecheckt zien elke force-push als een diverged history. Voor een artefact-branch is dat OK (niemand ontwikkelt erop), maar documenteer het gedrag in de eerste release-run zodat geen verwarring ontstaat als een tester dit opmerkt.
- Eventuele GitHub Action als vervolg op het handmatige script.

## Bin-scripts assessment

Drie bash-scripts in de repo, verschillende doelgroepen.

**Operator-only (blijven bash):**

- `bin/plugin-cache-prune`: draait op mijn macOS-machine om stale cache-directories op te schonen. Geen consumer raakt hieraan.
- `bin/plugin-versions`: idem, pre-commit hook en handmatige drift-checks.

Geen port nodig. Deze scripts verlaten mijn machine nooit.

**Consumer-facing (bash, afhankelijk van hoe Claude Code de Bash tool uitvoert op Windows):**

- `packages/autonomous/bin/relative-cron`: wordt via de Bash tool aangeroepen door de cron-skill in elke autonomous-loop iteratie. Draait dus op de consumer.

Niet zonder meer veilig aan te nemen dat Claude Code's Bash tool op Windows een POSIX-shell gebruikt. In de praktijk draait Claude Code op Windows vaak onder WSL2 of Git Bash, en dan werken bash-scripts. Er zijn echter configuraties waarin de Bash tool via PowerShell draait (bijvoorbeeld `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`), en daar breekt `relative-cron` zoals het nu geschreven is. Aanbeveling voor deze mission-scope: geen port nu, maar markeer als "verifieer op target consumer." Als mijn broer Claude Code via WSL/Git Bash draait, werkt het. Als hij Claude Code via PowerShell draait, vereist `relative-cron` een port naar Python of Node. Deze verificatie hoort bij de eerste test-installatie op Windows.

## Volgende stap

Aparte loop of implementatie:

1. `bin/marketplace-release` schrijven (dry-run + write modes).
2. Een eerste release-branch bouwen en verifiëren dat een Windows-consumer de plugin kan installeren.
3. `marketplace.json` entries updaten met `ref: release`.
4. Eventueel een GitHub Action voor automatische releases.

Deze loop produceerde alleen de aanbeveling. De implementatie wacht op een aparte `/autonomous:rover` dispatch.
