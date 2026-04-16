# Windows-compatibiliteit voor de leclause marketplace

Status: aanbevelingsdocument. Geen code change, dit is de voorbereiding op een implementatie die in een vervolgloop landt.

Scope: alle Windows-gebruikers van de leclause marketplace. Niet één specifieke consumer. Een oplossing die alleen voor één gebruiker werkt (handmatige resolved kopie, eenmalige SEED_DIR setup) valt daarmee af: elke Windows-consument moet `claude plugins install <plugin>@leclause` kunnen draaien en krijgen wat werkt, zonder verdere handeling.

## Probleemstelling

De leclause-marketplace gebruikt symlinks om skills tussen plugins te delen. Elke `packages/<plugin>/skills/<skill>` verwijst met `../../../skills/<skill>` naar de canonieke source onder de repo-root. Op macOS en Linux werkt dit direct: git bewaart de symlink bij clone, Claude Code kopieert de plugin naar zijn cache zonder te dereferencen, en de symlink blijft tijdens runtime werkend.

Op Windows breekt dit potentieel in TWEE lagen.

**Laag 1: git clone.** Git for Windows heeft `core.symlinks=false` als default. Zonder die instelling worden symlinks bij clone geconverteerd naar text files die het doel-pad als inhoud hebben.

**Laag 2: Claude Code cache-symlinks.** Empirisch op macOS getest: bij installatie via een github source kopieert Claude Code geen real content naar de cache, maar maakt absolute symlinks die naar de marketplace-clone wijzen (`cache/<marketplace>/<plugin>/<version>/skills/<skill>` → `/Users/.../plugins/marketplaces/<marketplace>/skills/<skill>`). Bij installatie via een lokale directory source kopieert Claude Code wel real content. Dit verschil suggereert dat github-source-installs op Windows een symlink-creatie-stap doorlopen die zelf admin of Developer Mode kan vereisen.

Combineer beide: zelfs als laag 1 wordt opgelost (door bijvoorbeeld een release-branch zonder symlinks), is laag 2 een aparte kwestie. De empirie ontbreekt om met zekerheid te zeggen dat Claude Code's install-stap op Windows zonder verdere configuratie absolute symlinks kan maken (of een copy-fallback heeft). Tot dat geverifieerd is op een Windows-machine, blijft elke aanbeveling deels speculatief.

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

`CLAUDE_CODE_PLUGIN_SEED_DIR` is een environment variable die Claude Code naar een voorgematerialiseerde plugins-directory laat wijzen. Dit is een consumer-side workaround: elke gebruiker zou zelf een resolved kopie van de repo moeten klaarzetten (bijvoorbeeld via `cp -rL`) en bij elke update opnieuw synchroniseren. Valt in dezelfde categorie als optie 1 en schaalt niet naar meerdere Windows-gebruikers. Niet gekozen.

Npm distribution is een echt alternatief. Elke plugin publiceren als npm package met een post-install script dat materialized files naar de plugin cache schrijft. Symlinks spelen geen rol meer. Nadelen: npm-account nodig, publish-workflow, versie-drift tussen npm en GitHub. De marketplace-entries zouden `source: npm` gebruiken in plaats van `source: github`. Te ver buiten de huidige architectuur, en voegt een tweede publicatiekanaal toe zonder sterk voordeel boven materialise-at-release. Niet gekozen.

## Aanbeveling: materialise-at-release

De structureel juiste aanpak is optie 4. Symlinks blijven de source-of-truth in de main branch. Een release-stap vertaalt ze naar echte directories in een artefact dat consumers installeren. De macOS-workflow blijft identiek aan vandaag; Windows-consumers krijgen werkende files (laag 1 weg).

**Waarschuwing.** Deze aanpak adresseert laag 1 (symlinks in de marketplace-clone). Laag 2 (Claude Code's cache-creatie-gedrag op Windows voor github sources) is niet gevalideerd vanaf macOS en blijft een open kwestie. Voor de eerste Windows-rollout is een echte Windows-test verplicht. Zonder die test is de claim "consumer hoeft niks te doen" speculatie.

Concreet:

1. **Source-of-truth blijft `main`.** Ik blijf met symlinks werken. `packages/<plugin>/skills/<skill>` verwijst zoals nu naar `skills/<skill>` onder de repo-root. Dual-publishing via het `leclause` bundle-plugin werkt op dezelfde manier.

2. **Nieuwe release branch (`release`) met materialized content.** Een script synct alles van `main` naar `release` en vervangt onderweg elke symlink door de echte directory-inhoud. Kandidaten voor de implementatie: `rsync -aL` gevolgd door een commit op `release`, of `git archive main | tar -x` met een losse symlink-resolving stap, of een build-directory die we force-pushen.

3. **`marketplace.json` wijst naar `release`.** Elke plugin-entry krijgt een expliciete `ref` field in zijn source, bijvoorbeeld `{"source": "github", "repo": "epologee/leclause-skills", "ref": "release"}`. Lokaal adden van de marketplace via een relatieve path blijft werken tegen `main` voor ontwikkelwerk; alleen de publieke install route via github.com haalt `release` op.

4. **Nieuwe script: `bin/marketplace-release`.** Dit is het workhorse. Dry-run modus voor diffen, write-modus voor daadwerkelijk bouwen en force-pushen van `release`. Later eventueel te vervangen door een GitHub Action die bij elke push op `main` de release branch bijwerkt.

5. **Versioning koppelt main aan release.** `plugin-versions` telt commits per plugin op de branch waar het draait. Als `release` wordt force-pushed met één mirror-commit, zou het tool op die branch overal "1.0.1" rapporteren. Oplossing: `plugin-versions --write` draait altijd op `main`, het resultaat wordt in de plugin.json files van de release-build geschreven, en die files gaan mee in de force-push. Het tool zelf verandert niet; de release-script roept het aan op main, leest de versies, en commit ze naar release. Dit is niet optioneel: Claude Code detecteert updates via `plugin.json` version, dus release moet de correcte versies van main dragen of consumers missen nooit een update.

### Impact

- **`bin/plugin-versions`**: ongewijzigd. Operator-only, draait op macOS.
- **`bin/plugin-cache-prune`**: ongewijzigd. Operator-only, draait op macOS, schoont lokale cache.
- **`bin/marketplace-release`**: nieuw. Consumer-facing artefact wordt hiermee gebouwd. `rsync -aL` van de huidige checkout naar een temp-directory (resolveert symlinks naar echte directories), force-pusht naar `release` branch van origin. Werkt op macOS en Linux (GitHub Actions).
- **`marketplace.json`**: ongewijzigd op zowel `main` als `release`. De branch-selectie zit in het `claude plugins marketplace add <owner>/<repo>@<branch>` commando dat consumenten runnen, niet in de marketplace.json zelf. Mac/Linux-consumenten gebruiken de default branch; Windows-consumenten voegen `@release` toe aan dat commando.

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

**Consumer-facing (bash, moet portable worden voor Windows-release):**

- `packages/autonomous/bin/relative-cron`: wordt via de Bash tool aangeroepen door de cron-skill in elke autonomous-loop iteratie. Draait dus op de consumer.

Omdat de scope alle Windows-gebruikers omvat, kunnen we niet aannemen dat iedereen Claude Code via Git Bash of WSL draait. Sommigen gebruiken native PowerShell (o.a. via `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`), en daar breekt `relative-cron` meteen. Port voor de eerste Windows-release: herschrijven naar Node of Python. Node heeft de voorkeur omdat Claude Code zelf al Node vereist, dus er komt geen extra runtime-eis bij. Python werkt ook, maar zou een nieuwe dependency introduceren voor wie hem niet heeft staan.

Dit is geen "later observeren"-beslissing meer: zonder port blijft autonomous op PowerShell-setups stuk. De port hoort bij de implementatie-loop, niet erna.

## Volgende stap

Aparte loop of implementatie, in deze volgorde:

1. `packages/autonomous/bin/relative-cron` porten naar Node. Dit blokkeert PowerShell-setups en moet vóór de eerste Windows-release af zijn.
2. `bin/marketplace-release` schrijven (dry-run plus write modes, rsync -aL plus plugin-versions write).
3. Een eerste release-branch bouwen en op een echte Windows-machine verifiëren dat (a) `claude plugins install autonomous@leclause` slaagt zonder Developer Mode of admin, (b) de cache real content of werkende symlinks bevat, (c) `/autonomous:help` of een andere skill draait. Laag 2 (cache-symlink-creatie) wordt hier voor het eerst écht getest.
4. `marketplace.json` entries updaten met `ref: release`.
5. GitHub Action voor automatische release-updates bij elke push op `main`. Niet optioneel als we alle Windows-gebruikers willen bedienen; handmatige runs betekenen periodes waarin release achterloopt op main.

Deze loop produceerde alleen de aanbeveling. De implementatie wacht op een aparte `/autonomous:rover` dispatch.
