# Vertical-Slice Commit Discipline (gitgit plugin extension)

status: draft
datum: 2026-04-30
categorie: hook + skill
impact: high
confidence: hoog

> **Deliverable van dit document is een plan, niet een implementatie.** Geen code, geen hook scripts, alleen het ontwerp en de onderbouwing.

> **Geen MVP-mindset.** Dit plan beschrijft het complete, robuuste eindontwerp. Slices in sectie 10 zijn niet afgekapte minimum-uitvoeringen die we later uitbreiden, ze zijn onafhankelijk werkende verticale snedes die samen de volledige scope leveren. Elk slice is testable en verifiable; geen halve afwerkingen, geen "later uitbreiden". De volgorde dient verificatie en isolatie, niet scope-reductie.

## 1. Probleemstelling

Claude Code's reflex is "gewoon gaan programmeren". Resultaat: grote zwabberende commits die meerdere concerns tegelijk doen, met tests als bonus aan het eind en een commit body die ofwel ontbreekt ofwel de diff parafraseert. CI vangt alleen coverage-drop op, niet de kwaliteitsval van de commit-historie zelf.

De operator's intuïtie: laat het commit-onderwerp gewoon doen wat het al deed (één imperatieve zin van max 72 tekens), maar zet de body in als verplichte verantwoording over hoe de commit zich aan vertical-slicing-discipline heeft gehouden. Zonder die body, geen commit. Verplichte sleutels in de body zouden bijvoorbeeld zijn: welke tests draaiden groen, hoe is dit een verticale snede, was de test echt rood eerst, waarom wel of niet cucumber.

Hooks rond `git commit`, `git commit --amend` en `git push` moeten dit afdwingen. Het idee landt in de bestaande `gitgit` plugin (operator-besluit), waarbij de huidige git-rakende guards en user-level hooks vrijelijk verplaatst, samengevoegd of vervangen mogen worden.

## 2. Empirische bevindingen uit de geanalyseerde monorepo

Subagent-analyse op 50 commits uit 2024-01-01 tot 2025-10-01 ("nette periode") en 25 commits uit 2025-10-01 tot 2026-04-30 ("rommel periode"), human-authored, zonder dependabot, zonder merges, zonder version bumps. De broncode is een private codebase; commit-SHAs en bodies zijn hier geanonimiseerd of vervangen door representatieve hypothetische voorbeelden.

### 2.1 Wat NIET het verschil maakt

Onverwacht resultaat: meerdere kandidaat-signalen blijken niet te discrimineren tussen de twee periodes.

| Signaal | Nette periode | Rommel periode |
|---------|---------------|----------------|
| Imperatieve mood in subject | 100% | 100% |
| Sentence-case capitalisatie | 100% | 100% |
| Conventional-commits prefix (feat:/fix:) | 0% | 0% |
| Past tense verbs | 0% | 0% |
| Avg subject length | 55 tekens | 58 tekens |
| Touches both `app/` and `spec/` | 28% | 36% (hoger!) |

De hypothese dat de "rommel periode" geen vertical slices meer maakt op file-niveau, klopt niet. De rommel periode raakt zelfs vaker app + spec samen aan. Conventional-commits is geen historische conventie waar van afgeweken werd; die was er nooit. Subject-vorm is identiek.

### 2.2 Wat WEL het verschil maakt: het body

| Signaal | Nette periode | Rommel periode |
|---------|---------------|----------------|
| Commit heeft uitleg-body (>1 regel) | 82% | 0% |
| WHY-paragraaf | ~70% van commits met body | n/a |
| Technische root-cause uitleg | ~60% | n/a |
| Resolves-URL footer | 24% | 0% |
| Co-authored-by trailer | 24% | 0% |

Concrete voorbeelden uit de nette periode:

Een geanonimiseerd voorbeeld uit de nette periode (representatief, geen letterlijke kopie):

> Ignore invalid meter reading for start/stop transaction
>
> When handling `StartTransaction` or `StopTransaction` messages, the
> payload might contain a meter reading that is, by domain terms,
> invalid. If so, we want to ignore the meter reading and still
> properly handle the transaction event to make sure we don't miss
> session starts or stops.
>
> Resolves https://example.org/backlog/issues/1234

Een tweede voorbeeld uit de nette periode: root-cause body over division-by-zero in `WeightedAverage#call`, eindigt met een issue-tracker URL.

Concrete voorbeelden uit de rommel periode (geanonimiseerde subjects):

- subject "Expose device enrollment endpoint", 111 insertions, geen body.
- subject "Make enrollment race-safe and conflict-aware", 88 insertions, geen body.
- subject "Enroll devices by id and identifier", 169 insertions, geen body.
- subject "Hand off provisioning entirely to web subsystem", 580 deletions, geen body.

### 2.3 Eerlijke nuances

- De "neat" periode had ook legitiem-single-line commits: 1-insertion sorteer-tweaks, 1-insertion Docker-image-aanpassingen, 1-insertion suggesties uit code-completion tooling, en gitignore-tweaks. Naive "elke commit moet een body hebben" geeft dus ~18% false positives.
- Claude Code integratie in de geanalyseerde repo verscheen al **eind september 2025**, niet pas na oktober. De gedragsverschuiving valt iets eerder in dan de operator hypothiseerde. De analyse-window-grens van 1 oktober 2025 is dus een conservatieve afkapping.
- Vertical-slicing op file-niveau is niet de discipline die verloren ging. Het was de **uitleg-discipline** in de body. De operator's intuïtie wijst dus richting de juiste interventie (verplicht body), maar via een ander mechanisme dan "frontend + backend + spec teller".

### 2.4 Mechanisch detecteerbare regels

| Regel | TP rate | FP rate | Aanbeveling |
|-------|---------|---------|-------------|
| A: single-line commit | 100% (n=25 in messy sample) | 18% (n=50 in neat sample) | Warn, niet blokkeren |
| B: single-line + >50 insertions | n=4 in messy sample, 0 FP-observaties in neat sample | indicatief, niet conclusief | Strong-warn tot shadow-data (slice 3) een hardere conclusie wettigt |
| C: single-line + >20 insertions | tussen A en B in | matig | Strong-warn (tussenvorm) |

De n=4 voor regel B is statistisch ontoereikend voor een "block" classificatie; het 95% confidence-interval rond 0% FP-rate strekt zich op vier observaties uit tot meer dan 60%. Slice 3's shadow-mode verzamelt veertien dagen extra data tegen het volledige body-schema; pas na die periode kan een evidence-based block-aanbeveling gemotiveerd worden. Voorlopig blijven A, B, C alle drie warn-signalen die de auteur zien moet, niet blokkades die de commit afkappen.

Voor een body-schema dat verder gaat dan deze drie heuristieken, is detectie niet meer mechanisch op de **diff** te baseren. De detectie moet dan op de **body-tekst** zelf, met sleutelwoord-grammar (zie sectie 5).

## 3. Externe research samenvatting

### 3.1 Vertical-slicing canon

Geen van de bekende auteurs (Wikipedia, Bogard, Cockburn's "Walking Skeleton", Cohn, Patton, Kniberg's "Elephant Carpaccio") biedt **kwantitatieve, machine-detecteerbare heuristieken**. De definities zijn allemaal kwalitatief: een vertical slice is een doorsnede die alle architecturale lagen raakt (UI / business / data) en zelfstandig functioneert. De TDD-inclusieve definitie van outsidein.dev is direct relevant voor commit-discipline: schrijf eerst een falende E2E-test, observeer de RED, bouw de slice op met inner red-green-refactor cycles. Bron: https://outsidein.dev/react/vertical-slice/.

Mehmet Erturk's "Full-Stack Vertical Slices" (https://ertyurk.com/posts/full-stack-vertical-slices-the-only-way-to-ship-with-ai/) is de meest direct toepasbare bron: hij definieert een vertical-slice commit als "Database migration, backend handler, data access layer, API types, frontend components, documentation. One commit." Het artikel bespreekt waarom deze granulariteit met AI-agents werkt (self-contained context, immediate validation, parallel independence, smaller blast radius). Onze Slice-trailer is een synthese die deze observatie codificeert in classificatie-tokens; de classificatie zelf (handler + service + spec, of een opt-out enum) is plan-eigen, geen citaat.

Implicatie voor de plan: omdat de canon geen detecteerbare heuristieken levert, kan de hook niet eisen dat alle lagen geraakt zijn. De hook valideert alleen dat de **author classificeert** zijn commit (Slice-trailer met enum opt-out of vrije tekst), en dat de tests die hij claimt aanwezig zijn in de tree.

### 3.2 Conventional Commits en git-trailers

De Conventional Commits spec (https://www.conventionalcommits.org/en/v1.0.0/) definieert subject + optionele body + optionele footer. De footer-definitie is expliciet "inspired by the git trailer convention" en gebruikt `key: value` of `key #value` regels. Geen verplichte trailer-keys behalve `BREAKING CHANGE`. De spec-extensie waarin git-trailers de canonieke footer-vorm worden, is voorgesteld in https://github.com/conventional-commits/conventionalcommits.org/issues/179 maar niet formeel geadopteerd.

Het git-native mechanisme `git interpret-trailers` (https://git-scm.com/docs/git-interpret-trailers) bestaat sinds 2.2.0 en parseert de trailer-block aan het einde van een commit-message. `--parse` mode is de juiste call voor een hook: extract de trailers, valideer keys en values. **Dit elimineert de noodzaak voor een eigen parser** in `commit-body.sh`.

De Linux kernel-traditie (`Signed-off-by`, `Tested-by`, `Reviewed-by`, `Acked-by`, `Reported-by`, `Fixes:`) is het canonieke voorbeeld van een trailer-vocabulary. Bron: https://docs.kernel.org/process/submitting-patches.html. Belangrijk: `Tested-by:` registreert *wie* getest heeft, niet *wat*. Ons voorgestelde `Tests:` met test-paden is een nieuwe conventie zonder precedent in de kernel.

Angular's commit guidelines (https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md) zijn de enige mainstream-conventie die conditioneel een commit-type vrijstelt van body: `docs` is exempt, alle andere zijn body-verplicht (>= 20 chars). Dit is het canoniek precedent voor de **Slice opt-out enum** uit sectie 5.2.

Gerrit's `commit-msg` hook (https://gerrit-review.googlesource.com/Documentation/cmd-hook-commit-msg.html) is het canoniek model voor "een hook die idempotent een verplichte trailer injecteert" en is daarmee een referentie voor `prepare-commit-msg` die staged-diff-detectie kan gebruiken om de Slice-classificatie alvast in te vullen.

### 3.3 Hook tooling

| Tool | Native install survives clone? | `commit-msg` ondersteund? | Bypass |
|------|-------------------------------|---------------------------|--------|
| native git hooks (`.git/hooks/`) | nee | ja | `--no-verify` |
| `core.hooksPath` met versioned dir | nee zonder setup-step | ja | `--no-verify` |
| Husky (Node) | ja, via `prepare` npm script | ja | `--no-verify` |
| Lefthook (Go) | ja, via `postinstall` of direnv | ja | `LEFTHOOK=0` of `--no-verify` |
| pre-commit framework (Python) | nee zonder `pre-commit install` | ja (commit-msg stage) | `--no-verify` |

Bronnen: https://typicode.github.io/husky/, https://github.com/evilmartians/lefthook, https://pre-commit.com/, https://git-scm.com/docs/githooks.

**Kritieke bevinding voor onze plan:** Claude Code plugins kennen geen native PreCommit / PostCommit hook event. Het hook-systeem (PreToolUse, PostToolUse, SessionStart, Stop) is gescheiden van git hooks. De feature request voor PreCommit/PostCommit lifecycle events (https://github.com/anthropics/claude-code/issues/4834) is door Anthropic gesloten als "not planned". De PreToolUse:Bash matcher op `git commit` is dus de **definitieve** route voor Claude-aangedreven commits, geen tijdelijke werkwijze. Voor commits buiten Claude (CLI, IDE, andere tools) moet een git-native hook actief zijn. Dat vereist een per-repo install-stap. Ons `/gitgit:install-hooks` slice is dus **noodzakelijk**, niet optioneel.

### 3.4 Bestaande vertical-slice / TDD-discipline tools

Geen exact precedent. De dichtstbijzijnde:

- **tdd-bdd-commit** (https://github.com/matatk/tdd-bdd-commit, archived 2021): wrapper-commando's `commit red`, `commit green`, `commit refactor` die naming-prefixen aan het subject zouden toevoegen. Geen technische enforcement; bypassbaar door direct `git commit`. Bovendien volgens de archived repo nooit voltooid (commit-message formatting features niet geimplementeerd). Het laat geen gat achter dat onze plan invult, maar zelfs het closest precedent is dunner dan op het eerste oog leek.
- **TDD Guard** (https://github.com/nizos/tdd-guard): Claude Code plugin die file-modificaties intercepteert via PreToolUse:Edit/Write hooks om implementatie zonder voorafgaande failing test te blokkeren. Structurele beperking die uit het ontwerp volgt: PreToolUse op file-edit kan blokkeren wanneer er geen recente test-run-evidence is, maar kan niet inhoudelijk verifieren dat een test daadwerkelijk in falende staat geobserveerd is door de auteur. Een AI die compliant lijkt kan in principe werk reframen rond de gates. Hetzelfde structurele patroon geldt voor onze body-trailers; zie sectie 9.4.
- **Danger.js** (https://danger.systems/js/): PR-level CI-enforcement via `danger.git.modified_files`. Kan "app code changed without test changes" als warning afdwingen op PR-niveau, niet per-commit. Geen vertical-slice taxonomie.
- **git-test** (https://github.com/mhagger/git-test): runt tests tegen commits en slaat resultaten op in git-notes geindexeerd op tree-SHA. **Plaatst resultaten niet in de commit body.** Het zou kunnen worden geadapteerd: pre-commit runt tests, slaat groen-status op in `~/.claude/var/`, commit-msg hook verifieert de gecachte status. Geen bestaand project doet dit zo.
- **gitlint** (https://jorisroovers.com/gitlint/): commit-msg linter met built-in skip-patterns voor merge/revert/fixup/squash. Regex-rules ondersteund. Geen vertical-slice of test-evidence concept ingebouwd.
- **commitlint** (https://commitlint.js.org/) ondersteunt `body-empty: [2, 'never']`, `trailer-exists`, `body-min-length`. Geen native conditionele body-eis op commit-type. Custom plugins zoals `@mridang/commitlint-plugin-conditionals` vullen dit gat.

Conclusie: **dit ontwerp heeft geen direct precedent in de onderzochte bronnen**. Wel zijn alle bouwblokken al beschikbaar (git-trailers parser, commitlint regels, husky/lefthook installer, gitlint skip-patterns). Implementatie is samenstellen, geen uitvinden.

### 3.5 Steelman-kritiek

**False positives.** Doc-only, config-only, refactor, WIP, fixup, squash, merge, revert: allemaal commits die geen vertical-slice body horen te dragen. Industry-praktijk (commitlint, gitlint defaults; Angular's docs-exempt) bevestigt dat opt-outs noodzakelijk zijn. Zie sectie 6.5.

**Gaming.** Het diepste probleem. TDD Guard toont een vergelijkbare structurele grens: een PreToolUse-gate kan blokkeren maar kan geen mens-of-AI-coöperatie afdwingen waar die niet is. Hetzelfde geldt voor onze trailers. `Tests: spec/foo.rb` waar foo niet echt gerund is, `Red-then-green: yes` waar geen rood gezien is, `Slice: handler + service + spec` waar de service niet aangeraakt is. Mitigaties die wel werken: pad-bestaansvereiste tegen de tree, anti-copy-paste op de WHY-paragraaf, opt-out enum dwingt classificatie, slice-9 cache vereist een recente run-entry. Mitigaties die NIET werken zonder duurdere infrastructuur: inhoudelijk verifieren dat de tests groen zijn op exact deze diff (vereist tree-SHA matching die niet-triviaal is), inhoudelijk verifieren dat de WHY klopt met de code.

**Slow-down.** Het bekendste anti-precommit-essay (https://jyn.dev/pre-commit-hooks-are-fundamentally-broken/, HN-thread https://news.ycombinator.com/item?id=46398906) waarschuwt: hooks die meer dan een paar seconden kosten worden via `--no-verify` omzeild. Hooks die conflicteren met `git rebase -i` of de working tree corrumperen verliezen vertrouwen. **Onze hook valideert alleen tekst-structuur, runt geen tests.** Latency is verwaarloosbaar. Voor latere uitbreiding met test-runner integratie (slice 9): plaats die in pre-push, niet pre-commit, conform de HN-consensus.

**`--no-verify` reflex.** Geen publieke usage-statistieken gevonden. Kwalitatieve consensus: hooks die als noise voelen worden vermeden. Mitigatie: maak de error-messages concreet en actionable (de gebruiker weet exact welke trailer ontbreekt en krijgt een voorbeeld), niet generiek ("commit message invalid"). Log `--no-verify` gebruik naar `~/.claude/var/gitgit-no-verify.log` zodat het terug-zichtbaar is.

**Dictation-probleem.** Wanneer Claude zowel de code als de body schrijft, is de body Claude's verhaal over zichzelf, niet onafhankelijk getuigde evidence. TDD Guard's auteur erkent dit. Onze concrete mitigaties: pad-bestaansvereiste op `Tests:`, anti-copy-paste op WHY, opt-out enum op Slice. Wat onbereikbaar blijft: semantische verificatie. Zie sectie 9.4 voor de bredere bespreking en de slice 9 uitbreiding (test-runner cache).

### 3.6 commit-msg vs prepare-commit-msg vs pre-commit timing

Per https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks:

- **pre-commit** ziet de diff, niet de message. Goed voor: tests runnen, lint, format checks.
- **prepare-commit-msg** krijgt het commit-type als parameter (`merge`, `squash`, `template`, `commit`, `message`). Goed voor: pre-fill van een template op basis van detecteerbare info (bv. detected file layers in staged diff naar `Slice:`-suggestie). Skip-detectie voor merge/squash/fixup hoort hier; sneller dan pas in commit-msg te skippen.
- **commit-msg** krijgt het pad naar de message-file. Goed voor: structurele validatie van het bericht. Reject is hard; gebruiker moet `git commit` opnieuw uitvoeren.

Voorgestelde combinatie: `prepare-commit-msg` voor template-fill (slice 8), `commit-msg` voor validatie (slice 6). Daarbovenop de PreToolUse:Bash guard (Claude-side, slice 3-5) die zowel kan parsen als blokkeren. De drie hooks delen één validator (`lib/validate-body.sh`, slice 1) zodat hun gedrag niet kan diverge.

### 3.7 De "Tests-Run in body" pattern is niet gevonden in de onderzochte bronnen

Geen project gevonden in de doorzochte bronnen dat test-evidence-paden in de commit body opneemt als verplichte trailer. De search heeft niet uitputtend gekeken naar grote open-source monorepos (Chromium, Firefox, LLVM hebben uitgebreide commit-msg conventies); een rigoureuze bevestiging van "ongekend" zou diepere search vragen. Voor het plan accepteren we de bevinding als zwakke positieve assertie: het patroon is niet algemeen ingeburgerd, ook al kan het lokaal in een ons onbekend project bestaan. De redenen waarom een algemeen ingeburgerde versie niet te verwachten valt:

1. **Vertrouwensprobleem.** De claim is niet uit de message verifieerbaar.
2. **Automation-gat.** Geen standard mechanisme tussen test-runner output en commit-message-write moment.
3. **Pre-push vs commit timing.** Teams runnen tests typisch op pre-push of CI, niet per-commit.

Onze plan hangt op (1). Pad-bestaansvereiste lost dit deels op (een AI moet wel naar een bestaand pad wijzen). Volledig oplossen vereist test-runner integratie via een lokale run-cache, dat is slice 9 in dit plan en zit dus volledig in scope.

### 3.8 Implicaties voor het plan

Concrete aanpassingen die uit de externe research volgen:

1. Gebruik `git interpret-trailers --parse` als de body-parser; schrijf geen eigen line-based parser.
2. Hanteer Angular's docs-exempt-precedent voor Slice opt-out enum (`docs-only`, `config-only`, `chore-deps`).
3. Hanteer gitlint's default skip-patterns voor merge/revert/fixup/squash; documenteer ze expliciet.
4. Wees transparant over de mechanische-vs-semantische discipline grens (TDD Guard's eerlijkheid is een te imiteren standaard, niet een beschuldiging).
5. Behoud de test-runner integratie als slice 9, met de cache-aanpak die geen test-runs aan commit-tijd toevoegt (alleen lookup). Volledig in scope, niet uitgesteld.
6. Beschouw commitlint als alternatief implementatie-middel voor de git-native commit-msg hook (sectie 6.3); de bash-route blijft mogelijk maar commitlint geeft een bewezen base.
7. `/gitgit:install-hooks` is niet optioneel, het is de enige route voor non-Claude commits. De alternatieve route via een native Claude Code PreCommit-event is door Anthropic afgewezen (https://github.com/anthropics/claude-code/issues/4834 closed not planned), dus de twee-laagse architectuur (PreToolUse:Bash + git-native hook) is de definitieve, niet voorlopige, opzet.

## 4. Bestaande discipline-fragmenten in de cloud config

Subagent-inventarisatie van `~/.claude/CLAUDE.md`, `~/.claude/skills/`, en plugin-caches. De volgende fragmenten raken commits, tests, vertical slices, of TDD en zijn migratie-kandidaten.

### 4.1 In `~/.claude/CLAUDE.md` (soft rules)

| Naam | Categorie | Huidige vorm |
|------|-----------|--------------|
| Tests horen bij hun feature | vertical slice | tekstregel |
| Reproduceer voor je fixt (RED voor GREEN) | TDD | tekstregel |
| Diagnose-blok voor de eerste edit bij bug-melding | verificatie | tekstregel |
| Groene tests zijn geen pauzemoment | discipline | tekstregel |
| Push vereist expliciete user-go | push gate | tekstregel + pre-push hook elders |

### 4.2 In skills onder `~/.claude/skills/` (soft rules)

`git-and-github` skill:
- Activity-word ban op commit subject (`Fix/Improve/Update/Change/Refactor`)
- 50 chars target, 72 max, imperatief Engels
- "Tests groen is geen push-trigger"
- "Branch mag alleen eigen remote tegenhanger tracken"
- "Nooit squash-merge"
- "Logisch onafhankelijke wijzigingen zijn aparte commits. Tests en implementatie vormen één atomaire commit"
- "Commit approval is ALTIJD eenmalig"
- "Amend is verboden tenzij onpushed secrets/PII strippen"

`testing-philosophy` skill:
- TDD workflow RED-GREEN-REFACTOR ("NOOIT implementatie schrijven voordat je een falende spec hebt gezien")
- "RED -> GREEN -> REFACTOR is een doorlopende flow"
- "De spec begrenst het werk"
- UI/UX bugs vereisen Cucumber scenario, geen unit spec
- Gherkin declaratief, niet imperatief
- Geen `@wip` tags zonder spec-implementatie
- Mass test deletion zonder per-geval mapping is een smell

`programming-philosophy` skill:
- Beck-baseline: intent-revealing names, Red-Green-Refactor, KISS
- "Falende test suite is een actieve blocker"

`verification-and-diagnosis` skill:
- "Reproduceer de warning voordat je fixt"
- Verificatie in juiste context

### 4.3 In `dont-do-that` plugin (hard hooks)

Bron: `packages/dont-do-that/hooks/guards/`.

| Hook | Triggert op | Wat doet het |
|------|-------------|--------------|
| `commit-rule.sh` | PreToolUse:Bash op `git commit` | 14 rules met rotatie, ack-rule<N> token-vereiste; rule 1 (activity-word) en rule 2 (trigger-as-reason) blokkeren altijd; rest is rotating reminder |
| `commit-format.sh` | idem | 72-char ceiling op alle regels, blank line tussen subject en body, 50-char aspirational warn |
| `dash.sh` | PostToolUse Edit/Write/Bash | em-/en-dash detectie in `.md`/`.txt`/`.mdx` en bash commands |
| `premature.sh` | Stop | blokkeert antwoorden zonder substantive sentence + 🏁/🚦 of trailing `?` |
| `compliance.sh` | Stop | blokkeert reflexieve "Wil je dat ik...?" vragen |
| `verify.sh` | Stop | blokkeert verificatie-delegatie naar user |
| `false-claims.sh` | Stop | blokkeert "was already failing" claims zonder bewijs |
| `cache.sh` | Stop | blokkeert cache-blame op localhost |
| `tool-error.sh` | Stop | blokkeert opgeven na tool-failure |
| `followup.sh` | PreToolUse:Bash op `gh api` | blokkeert deferral-language in PR-body |

De **git-rakende** items (`commit-rule.sh`, `commit-format.sh`) verhuizen naar gitgit (operator-besluit). De rest blijft in `dont-do-that`.

### 4.4 In `~/.claude/hooks/` (user-level)

| Hook | Wat doet het | Migratie |
|------|--------------|----------|
| `block-coauthored-trailer.sh` | blokkeert `Co-Authored-By:` op `git commit` | naar gitgit `commit-trailers.sh` |
| `warn-untested-commits.sh` | warn (exit 0) als staged diff app-code heeft maar geen tests | naar gitgit `commit-body.sh`, hardened naar block-with-Slice-justification |
| `block-git-dash-c.sh` | blokkeert `git -C` gebruik | naar gitgit `git-dash-c.sh`, scope ongewijzigd |

## 5. Voorgesteld commit body schema

### 5.1 Ontwerpprincipes

1. **Subject blijft zoals nu.** Imperatief Engels, 50/72 chars, geen activity-word, geen "Address review". Dit is al ingedekt door bestaande dont-do-that guards die migreren.

2. **Body is verplicht voor non-trivial commits.** Trivial = `single-line OK` per regel A uit sectie 2.4: max 5 insertions, max 1 file. Boven die drempel: body verplicht.

3. **Body bestaat uit twee delen: vrije WHY-paragraaf + gestructureerde footer trailers.** Dit mirrort wat de nette historische periode al deed (WHY + Resolves) en wat git-trailers natively ondersteunen via `git interpret-trailers`. Zonder uitvinden van een nieuwe parser-grammatica.

4. **Trailers gebruiken kernel/Gerrit-stijl `Key: Value` op aparte regels onderaan.** Dit is een conventie die git zelf herkent en die door tools zoals commitlint plug-ins gevalideerd kan worden.

5. **De WHY-paragraaf wordt niet inhoudelijk gevalideerd** (te makkelijk te bullshitten). Wel structureel: minimaal N regels, niet identiek aan een eerdere commit op de branch (anti-copy-paste).

6. **De trailers zijn wel structureel detecteerbaar.** Sleutelwoorden, waarden in een verwacht formaat (path, URL, een van een vaste set tokens).

### 5.2 Voorgestelde trailers

| Key | Value | Verplicht? | Detectie |
|-----|-------|------------|----------|
| `Tests` | path of pad-lijst (komma-gescheiden) van specs die groen draaiden voor deze commit | ja, behalve bij `Slice: skipped-...` opt-out | regex op pad-vorm; pad moet bestaan in HEAD-tree of in staged diff |
| `Slice` | one-line beschrijving van de verticale snede, OF een opt-out token | ja | enum opt-out tokens: `docs-only`, `config-only`, `migration-only`, `chore-deps`, `revert`, `merge`, `wip`. Anders vrije tekst >= 10 chars |
| `Red-then-green` | `yes` (test was rood gezien) of `n/a` met reden | ja, behalve bij `Slice: docs-only` of `config-only` of `chore-deps` | enum + optionele rationale string |
| `Resolves` | URL naar issue/Sentry/incident, of `none` | optioneel | URL-vorm of letterlijk `none` |
| `Cucumber` | `applicable` (en gebruikt), `n/a` met reden waarom unit volstaat, of weglaten | optioneel | enum + reden-string |

### 5.3 Voorbeeld-commit (hypothetisch)

```
Drop invalid meter reading on transaction events

When `StartTransaction` or `StopTransaction` messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts and stops in
analytics. This change keeps the transaction event but discards
just the bad reading, restoring the visibility we lost.

Tests: spec/services/session_spec.rb#start_event_with_bad_reading,
       spec/services/session_spec.rb#stop_event_with_bad_reading
Slice: handler + service + spec
Red-then-green: yes
Resolves: https://example.org/backlog/issues/1234
```

### 5.4 Voorbeeld voor een opt-out commit

```
Bump bundler to 2.5.18

Tests: spec/spec_helper.rb (suite still loads)
Slice: chore-deps
Red-then-green: n/a (no behavior change)
```

### 5.5 Hook grammar (informeel)

De hook-detectie steunt op `git interpret-trailers --parse` (sinds Git 2.2.0; bron: https://git-scm.com/docs/git-interpret-trailers). Geen eigen parser. De hook leest stdin (de commit-body) en pipet door:

```bash
trailers=$(git interpret-trailers --parse <<< "$body")
```

De terugkerende output is een lijst `Key: Value` regels in canonical form, één per trailer. De hook valideert daarna:

- `Slice` aanwezig in de output, value niet leeg.
- Als `Slice` value niet in opt-out enum (`docs-only`, `config-only`, `migration-only`, `chore-deps`, `revert`, `merge`, `wip`): `Tests` aanwezig en bevat minstens één path-vorm string. Het pad moet bestaan in HEAD-tree (`git ls-tree -r HEAD --name-only`) of in `git diff --cached --name-only`.
- Als `Slice` value niet in `docs-only`/`config-only`/`chore-deps`: `Red-then-green` aanwezig.
- WHY_BLOCK (alles vóór de trailer-block, gedetecteerd door de eerste `Key: Value`-regel) heeft minimaal 2 niet-lege regels OF >= 60 chars met een zinsterminator (`.`, `!`, `?`).
- Anti-copy-paste: SHA1 van WHY_BLOCK is niet identiek aan de SHA1 van de WHY_BLOCK van de vorige commit op deze branch (`git log -1 --pretty=format:'%B' HEAD`).

Validatieregels:
- `Slice` aanwezig en niet leeg (opt-out token of vrije tekst).
- Als `Slice` geen opt-out token is: `Tests` aanwezig en bevat minimaal één path-vorm string. Het pad moet bestaan in HEAD-tree of in `git diff --cached --name-only`.
- Als `Slice` geen `docs-only`/`config-only`/`chore-deps` is: `Red-then-green` aanwezig.
- WHY_BLOCK heeft minimaal twee regels OF eindigt op een zinsterminator (de aspirationele lengte 60-200 tekens, niet hard).
- Anti-copy-paste: WHY_BLOCK SHA1 is niet identiek aan de WHY_BLOCK SHA1 van de vorige commit op deze branch.

### 5.6 Wat is restoratie en wat is uitvinding?

Eerlijk onderscheid:

- **Restoratie van neat-period discipline:**
  - WHY-paragraaf in het body (was 70% in nette periode, 0% nu)
  - `Resolves` URL trailer (was 24%, was geen verplichting)
  - Co-authored-by als trailer (was 24%)
- **Nieuw uitgevonden om AI-reflex te bestrijden:**
  - `Tests:` trailer met expliciet pad-bestaansvereiste (forceert dat de AI naar een echt bestand wijst)
  - `Slice:` trailer met enum opt-outs (forceert classificatie)
  - `Red-then-green:` trailer (forceert TDD-bewustzijn op commit-tijd)
  - Anti-copy-paste WHY-detectie (verhindert "Tests: spec/foo.rb. Slice: backend + spec." als template)

De hybride is bewust. Pure restoratie is niet genoeg tegen de AI-reflex; pure uitvinding negeert wat al werkte. De plan-positie is: forceer de structuur die AI niet plausibel kan bullshitten zonder naar echte files te kijken, hou het free-prose deel kort genoeg om niet te beboeten en lang genoeg om mens en bot te dwingen te denken.

## 6. Hook architectuur

### 6.1 Twee enforcement-lagen

| Laag | Triggert | Pakt | Mist |
|------|----------|------|------|
| **PreToolUse:Bash guard in gitgit plugin** | elke `git commit` (zonder of met `--amend`) door Claude in een Claude Code sessie | Claude-aangedreven commits | menselijke commits buiten Claude |
| **git-native commit-msg hook** | elke `git commit` op de repo, ongeacht initiator | iedereen | repos zonder hook geinstalleerd |

Achtergrond uit externe research: Claude Code heeft geen native `PreCommit`/`PostCommit` lifecycle event en zal dat ook niet krijgen (https://github.com/anthropics/claude-code/issues/4834 is door Anthropic gesloten als "not planned"). PreToolUse:Bash op `git commit` is de definitieve canonieke route voor Claude-side enforcement; `PostToolUse + Bash(git commit:*)` zou achteraf draaien en kan niet blokkeren. Voor commits buiten Claude is een git-native hook de enige weg.

Beide lagen leveren we; één laag laten weg is niet robuust. De PreToolUse-guard heeft sessie-direct effect zonder per-repo install. De git-native hook is verplicht voor non-Claude paden en wordt geïnstalleerd via een nieuwe `/gitgit:install-hooks` skill. De twee lagen delen één validatie-implementatie (zie sectie 6.6) zodat hun gedrag niet hoeft te divergen. Bekende divergence-risico's blijven: de PreToolUse-guard parseert het bericht uit de bash command-string (heredoc of `-m`), de git-native hook leest het uit een file path; lossy parsing op edge cases is mogelijk verschillend. Plus omgevingsdrift: shell `$PATH`, git versie, of een verouderde geinstalleerde hook na een plugin-update. Sectie 6.6 documenteert de mitigaties.

### 6.2 PreToolUse:Bash guard

Volgt het bestaande dont-do-that patroon (`hooks/dispatch.sh` + `hooks/guards/<name>.sh`). Concreet voor gitgit:

- Nieuwe `packages/gitgit/hooks/dispatch.sh`. Identiek patroon als dont-do-that, dispatched naar `commit-subject.sh`, `commit-format.sh`, `commit-body.sh`, `commit-trailers.sh`, `git-dash-c.sh`.
- `packages/gitgit/hooks/hooks.json`: registreert PreToolUse:Bash matcher.
- `packages/gitgit/.claude-plugin/plugin.json`: bestaat al, alleen versie bumpt.

`commit-body.sh` parst het commit-bericht uit de bash command (heredoc-eerst, dan `-m`, gelijk aan commit-format.sh). Daarna:
1. Detecteer trivial: staged diff (`git diff --cached --name-only` + `--shortstat`), max 1 file en max 5 insertions, hele body mag dan single-line zijn. Skip rest.
2. Anders: parse trailers via `git interpret-trailers --parse <<< "$body"`. Valideer per regels uit 5.5.
3. Bij violation: emit `dd_emit_deny commit-body "<reason>"`. Geen ack-rule rotation; commit-body is een hard structuur, geen rotating-reminder.

Identiek voor `git commit --amend`: dezelfde guard fires omdat de bash command nog steeds met `git commit` start.

### 6.3 git-native commit-msg hook

Implementatiekeuze: **bash script** onder `packages/gitgit/skills/commit-discipline/git-hooks/commit-msg`, dat dezelfde gedeelde validator (sectie 6.6) aanroept als de PreToolUse-guard. Geen Node-dependency, portabel naar Linux/Windows met de bestaande `usr/bin/env` shebang-regel uit de marketplace, leunt op `git interpret-trailers` dat in alle moderne git-versies aanwezig is. Het commitlint-pad is overwogen en bewust verworpen: het zou een Node-toolchain in elke target-repo eisen en het plan losmaken van de bestaande dont-do-that bash-conventies.

`/gitgit:install-hooks` kopieert het script naar `.git/hooks/commit-msg` (of als `core.hooksPath` is gezet, naar die directory; detectie via `git config --get core.hooksPath`). De skill detecteert ook eventuele bestaande commit-msg hooks en weigert te overschrijven zonder expliciete `--force` flag, met een diff-preview van wat er zou veranderen.

Ondersteunt opt-out via:
- `git commit --no-verify` (git-native escape; hook draait dan niet; gebruik wordt gelogd via een corresponderende post-commit hook).
- Magic comment in body: `# vsd-skip: <reason>` (eigen escape; reason verplicht en non-leeg; gelogd naar `~/.claude/var/gitgit-skips.log` met SHA + branch + reason).
- Standard skip-patterns voor merge/revert/fixup/squash, conform gitlint defaults (https://jorisroovers.com/gitlint/latest/ignoring_commits/).

### 6.3a `prepare-commit-msg` voor template-fill

Onderdeel van het ontwerp, niet uitstel. `prepare-commit-msg` is het canonieke git-moment om een template voor te vullen op basis van detecteerbare info. Concreet: detecteer staged file types (frontend / backend / spec / migration / config), genereer een Slice-suggestie en vul de Tests-trailer met spec-paden uit `git diff --cached --name-only` die matchen tegen de project-conventies (`spec/`, `test/`, `__tests__/`, `*_spec.rb`, `*_test.go`, `*.test.js`, `*.feature`).

De auteur ziet de gevulde template in zijn editor en kan accepteren of overschrijven. Dit verlaagt friction voor de eerlijke auteur en is een no-op voor de oneerlijke (validatie blijft op commit-msg). Wordt geinstalleerd door dezelfde `/gitgit:install-hooks` skill als de commit-msg hook.

### 6.4 Pre-push hook (wip-gate, integraal onderdeel)

Het wip-gate is integraal in het ontwerp. Een commit met `Slice: wip` mag commit, maar mag niet pushen zonder expliciete operator-toestemming. Twee enforcement-paden, parallel aan commit-tijd:

- **PreToolUse:Bash guard** op `git push`: parseert de te-pushen commit-range (`git rev-list <upstream>..HEAD`), inspecteert elke commit body op `Slice: wip`, blokkeert als er één wip-commit in zit. Escape: env var `GITGIT_ALLOW_WIP_PUSH=1` voor de huidige bash-call, of de string `# allow-wip-push` in het laatste assistant-bericht (analoog aan dont-do-that's ack-rule pattern).
- **git-native pre-push hook**: identieke logica, geinstalleerd door `/gitgit:install-hooks` voor commits van non-Claude bronnen. Zelfde gedeelde validator (sectie 6.6).

Push-approval als concept (de bestaande "push vereist expliciete user-go" regel uit CLAUDE.md) is bredder dan dit plan en blijft user-level. De wip-gate is een specifieke uitbreiding voor het Slice-schema, niet een vervanging van de generieke push-gate.

### 6.6 Gedeelde validator (`lib/validate-body.sh`)

Eén bron-van-waarheid voor body-validatie, aangeroepen door:
- `commit-body.sh` (PreToolUse:Bash guard, Claude-side)
- `commit-msg` git-hook (alle commit-bronnen)
- `prepare-commit-msg` git-hook (voor template-fill, deelt parser maar niet validatie-output)
- toekomstige post-commit-mortems of CI-checks die hetzelfde schema willen toepassen

Interface:

```
validate_body <commit-msg-file-path>
  -> exit 0 + niets op stdout: gevalideerd OK
  -> exit 1 + diagnostic op stderr: violation (de aanroeper formatteert dit naar zijn eigen output: dd_emit_deny voor de PreToolUse guard, plain stderr voor de git-hook)
  -> exit 2: bestand niet leesbaar of geen commit-message-vorm (skipt validatie, niet-blokkerend)
```

**Divergence-risico's en mitigaties.** De gedeelde lib elimineert codepad-duplicatie maar niet alle divergence-bronnen:

- *Input-vorm verschil.* PreToolUse-guard parseert de bash command-string (heredoc of `-m` flag), git-native hooks lezen een file path. Mitigatie: `commit-body.sh` schrijft de geparsede body eerst naar een temp-file en roept daarna `validate_body $TEMPFILE` aan, zodat alle aanroepers dezelfde file-input route gebruiken. Edge case: command-string parsing zelf kan lossy zijn bij exotische quoting; BATS test-suite dekt heredoc met embedded `$`, `'`, `"`, en backticks.
- *Plugin-versie skew.* De git-native hooks worden door `/gitgit:install-hooks` op een tijdstip neergezet; daarna kan de plugin update zonder dat de geinstalleerde hooks meegaan. Mitigatie: elk geinstalleerd hook-script bevat een `vsd_plugin_version` constante, en draait bij elke aanroep een check tegen de huidige plugin-versie via een environment marker. Bij mismatch print de hook een waarschuwing en raadt aan `/gitgit:install-hooks --force` te draaien.
- *Shell-omgeving drift.* `$PATH`, `git`-versie, en `jq` beschikbaarheid kunnen verschillen tussen Claude's shell en de user's. Mitigatie: hooks gebruiken absolute paden naar `git` (`/usr/bin/env git`) en valideren bij start de aanwezigheid van `git interpret-trailers` (sinds 2.2.0). Bij absentie skipt de hook met een loud-but-non-blocking warning naar stderr.

Tests voor `validate_body` zijn unit-tests met BATS (Bash Automated Testing System) onder `packages/gitgit/test/validate-body/*.bats`. Elke regel uit sectie 5.5 heeft een eigen test-case met fixture commit-bodies. CI runt deze suite bij elke commit op de leclause-skills repo zelf. Cross-laag integratie-tests onder `packages/gitgit/test/cross-layer/` dekken de drie divergence-risico's hierboven met fixture-pairs (een PreToolUse-bash-string en de equivalente file-input moeten dezelfde validate-output geven).

### 6.7 Edge cases

| Geval | Detectie | Behandeling |
|-------|----------|-------------|
| Merge commit | `git rev-parse HEAD^2 2>/dev/null` heeft een SHA na merge; voor pre-commit is dit niet beschikbaar; de body komt van git zelf en heeft de "Merge branch ..." vorm | skip body validatie als subject begint met `Merge ` (case-sensitive) |
| Revert | subject `Revert "..."` (door `git revert` zo gegenereerd) | skip; reverts dragen de originele commit URL al |
| Initial commit | `git rev-parse HEAD` faalt vóór de eerste commit | skip |
| Cherry-pick | bevat vaak `(cherry picked from commit <SHA>)` | skip (origineel had al een body) |
| `git rebase -i` reword | gewone commit-msg trigger | normaal valideren |
| `git rebase -i` fixup/squash | de gecombineerde body wordt gevalideerd; gebruikelijk OK want de originele body migreert mee | normaal valideren |
| `--allow-empty` of `--allow-empty-message` | edge | hook skipt en logt |
| Niet-Claude bash invocatie via een script | de PreToolUse-guard ziet het als gewone Bash; werkt | normaal |
| Editor-mode commit (`git commit` zonder `-m`) | bestaande commit-rule.sh blokkeert dit al ("Editor-mode commit verbergt subject") | onveranderd |

## 7. Plugin structuur in `gitgit`

Volgt de bestaande leclause-skills conventies (zie `CLAUDE.md` en `README.md` van de repo):
- skills onder `packages/gitgit/skills/<skill>/`
- hooks onder `packages/gitgit/hooks/`
- portable shebangs (`#!/usr/bin/env node` of `#!/usr/bin/env python3`) in `bin/`, gewone bash in skills toegestaan
- versie in `packages/gitgit/.claude-plugin/plugin.json` volgt `1.0.{commit-count}` (auto via pre-commit hook)
- geen symlinks

Concreet de toe te voegen tree:

```
packages/gitgit/
├── README.md            (uitbreiden)
├── .claude-plugin/
│   └── plugin.json      (versie bump)
├── hooks/               (nieuw, volgt dont-do-that pattern)
│   ├── dispatch.sh
│   ├── hooks.json
│   ├── lib/
│   │   ├── emit.sh           (dd_emit_deny / dd_emit_pre_context helpers; sectie 9.5 bespreekt deduplicatie)
│   │   └── validate-body.sh  (gedeelde validator-functie voor PreToolUse-guard, commit-msg, prepare-commit-msg, en pre-push hooks)
│   └── guards/
│       ├── commit-subject.sh    (uit dont-do-that/commit-rule.sh)
│       ├── commit-format.sh     (uit dont-do-that/commit-format.sh)
│       ├── commit-body.sh       (nieuw: WHY + trailers validatie via validate-body.sh)
│       ├── commit-trailers.sh   (uit ~/.claude/hooks/block-coauthored-trailer.sh, scope verbreed naar trailer-policy)
│       ├── git-dash-c.sh        (uit ~/.claude/hooks/block-git-dash-c.sh)
│       └── push-wip-gate.sh     (nieuw: PreToolUse:Bash op `git push`, blokkeert wip-commits in range)
└── skills/
    ├── commit-all-the-things/   (bestaand)
    ├── commit-snipe/            (bestaand)
    ├── rebase-latest-default/   (bestaand)
    ├── merge-to-default/        (bestaand)
    ├── commit-discipline/       (nieuw)
    │   ├── SKILL.md             (documenteert body-schema, voorbeelden, escape-hatches; user-invocable als `/gitgit:commit-discipline` voor referentie)
    │   └── git-hooks/
    │       ├── commit-msg          (script, leunt op validate-body.sh)
    │       ├── prepare-commit-msg  (script, template-fill op staged diff)
    │       ├── pre-push            (script, wip-gate)
    │       ├── post-commit         (script, logt --no-verify gebruik via een sentinel-file mechanisme)
    │       └── README.md           (install-instructies)
    └── install-hooks/            (nieuw)
        ├── SKILL.md              (`/gitgit:install-hooks` om de git-native scripts in `.git/hooks/` te plaatsen, met core.hooksPath ondersteuning, conflict-detectie, force-flag)
        └── lib/
            └── install.sh        (idempotent install-script gebruikt door SKILL.md)
```

Het delen van `dd_emit_*` helpers tussen `dont-do-that` en `gitgit` is een open vraag in sectie 9 en wordt bewust niet vroegtijdig opgelost om premature abstractie te vermijden.

## 8. Migratie van versnipperde regels

Concreet werkblad voor de uitvoering. Drie kolommen: huidige plek, nieuwe plek in gitgit, transformatie.

| Huidige plek | Nieuwe plek in gitgit | Transformatie |
|--------------|------------------------|---------------|
| `dont-do-that/hooks/guards/commit-rule.sh` | `gitgit/hooks/guards/commit-subject.sh` | hernoem; optionele rotation rules 7-10 die niet over commits gaan, herzien |
| `dont-do-that/hooks/guards/commit-format.sh` | `gitgit/hooks/guards/commit-format.sh` | verplaats; geen wijziging |
| `dont-do-that/hooks/dispatch.sh` (git-rakende sectie) | `gitgit/hooks/dispatch.sh` | nieuwe dispatch met dezelfde signatuur; dont-do-that's dispatch verliest zijn git guards |
| `dont-do-that/hooks/lib/` (helpers) | `gitgit/hooks/lib/` | initieel kopie; later mogelijk gedeelde lib (open vraag) |
| `~/.claude/hooks/block-coauthored-trailer.sh` | `gitgit/hooks/guards/commit-trailers.sh` | absorbeer; verbreed naar trailer-policy (Co-Authored-By blokkeren tenzij user explicitly), behoud bestaande blocking gedrag |
| `~/.claude/hooks/warn-untested-commits.sh` | `gitgit/hooks/guards/commit-body.sh` (deelfunctie) | absorbeer; harden van warn naar block-tenzij-Slice-opt-out |
| `~/.claude/hooks/block-git-dash-c.sh` | `gitgit/hooks/guards/git-dash-c.sh` | verplaats; gedrag onveranderd |
| `~/.claude/CLAUDE.md` "Tests horen bij hun feature" | `gitgit/skills/commit-discipline/SKILL.md` | tekst-referentie, plus de hook bekrachtigt het via `Tests:` trailer + Slice non-opt-out |
| `~/.claude/CLAUDE.md` "Reproduceer voor je fixt" | idem (SKILL.md), plus `Red-then-green: yes` trailer enforcement | hook codificeert het |
| `~/.claude/CLAUDE.md` "Groene tests zijn geen pauzemoment" | blijft in CLAUDE.md (raakt geen commit-tijd) | geen migratie |
| `~/.claude/skills/git-and-github` regels over commits | gitgit `commit-discipline/SKILL.md` cross-reference | git-and-github wijst naar gitgit voor de commit body discipline; gitgit wijst terug voor branch / push / merge regels |
| `~/.claude/skills/testing-philosophy` regels over TDD/Cucumber | blijft daar; commit-body.sh refereert ernaar in error-messages | geen migratie van inhoud |
| `~/.claude/settings.json` enable van `dont-do-that@leclause` | settings.json blijft; gitgit hooks zijn auto-actief omdat plugin al enabled is | geen wijziging behalve plugin update |
| `~/.claude/var/commit-rule-state` (state file van commit-rule.sh) | `~/.claude/var/gitgit-commit-state` | hernoem; one-shot migratie-script in `/gitgit:install-hooks` |

Na migratie: `~/.claude/hooks/` bevat alleen de niet-git hooks die nog over zijn (auto-format.sh, block-autonomous-backlog-issues.sh). De user-level layer wordt slanker.

## 9. Risico's en open vragen

### 9.1 False positives

- **Doc-only commits met >5 insertions.** README-rewrite, planning-document toevoegen. Mitigatie: `Slice: docs-only` opt-out token. Open: moet dat opt-out automatisch toegekend worden als alle staged files een doc-extensie hebben (`.md`, `.txt`, `.rst`)? Voor- en nadeel afwegen.
- **Refactor zonder gedragswijziging.** Wel groot in regels, maar `Red-then-green: n/a` is gepast. Open: moet er een aparte opt-out `Slice: refactor-no-behavior-change` zijn, of volstaat het om `Red-then-green: n/a (refactor)` te accepteren?
- **Generated files.** Yarn lock, Gemfile.lock, schema.rb. Open: skipt het detecteren van trivial alleen `--shortstat <= 5 insertions`, of ook `--name-only` op een lockfile-pattern?

### 9.2 Gaming

- **Boilerplate body**: hetzelfde body-template recyclen over meerdere commits. Mitigatie: anti-copy-paste WHY-SHA-vergelijking. Default: vergelijk met de vorige 5 commits op de huidige branch. Open: ook tegen de laatste N main-commits, of is dat over-restrictive voor cherry-pick scenario's?
- **Path-bullshitting in `Tests:`**: een AI noemt een spec-pad dat lijkt te bestaan maar niet de relevante test runt. Mitigatie laag 1: pad moet bestaan in HEAD-tree of staged diff. Mitigatie laag 2: slice 9's test-runner cache vereist dat het pad een recente groene run heeft. Geen open vraag meer; beide mitigaties zijn in scope.
- **`Red-then-green: yes` zonder echt rood gezien te hebben.** Slice 9 lost dit op via de cache plus `/gitgit:saw-red <path>` skill: de cache moet een rood-entry voor het pad bevatten van vóór de groen-entry. Geen open vraag meer.

### 9.3 Slow-down

- **Iteratieve experimenten.** Spike-branches met 20 commits in een uur. Mitigatie: `Slice: wip` opt-out, met de pre-push wip-gate (sectie 6.4) die wip-commits weert van pushen. Geen cap op wip-aantal: de gate beschermt de remote, branchewerk lokaal vrij.
- **Time-pressure incidents.** Productie-fix om 3 uur 's ochtends. Mitigatie: `--no-verify` is niet uitgesloten; het is een bewuste escape. Logging is in scope: een `post-commit` hook (geinstalleerd door slice 6) detecteert via een sentinel-file of de validatie-hook gedraaid is. Bij absentie logt het naar `~/.claude/var/gitgit-no-verify.log` met SHA + branch + auteur + tijdstip, terug-zichtbaar voor latere audit.

### 9.4 Dictation-probleem

De diepste zorg: als de AI **zowel** de code als de body schrijft, hoeft de body niet de werkelijkheid te beschrijven. Het is een rapport over zichzelf.

TDD Guard (https://github.com/nizos/tdd-guard) toont dezelfde structurele grens: het tool intercepteert file-edits op het moment van schrijven, maar het kan niet uit de PreToolUse-context afleiden of de auteur de eerder vereiste failing test daadwerkelijk geobserveerd heeft of dat hij de gate cooperatief satisfied heeft door een test te schrijven die hij meteen weet te laten passen. Hetzelfde geldt voor onze trailers. We moeten dit expliciet erkennen, niet glimmen.

Concrete deel-mitigaties die WEL werken:
- `Tests:` pad-bestaansvereiste tegen HEAD/staged: forceert verwijzing naar echte file. Een verzonnen pad valt door de check.
- Anti-copy-paste WHY: forceert tekstuele variatie tussen commits. Een AI die N commits met hetzelfde body-template wil afgeven wordt geblokkeerd.
- Slice opt-out enum: forceert classificatie naar één van een vaste set. Geen vaag "we touched some files".

Wat NIET werkt zonder extra infrastructuur:
- Inhoudelijk verifieren of de WHY-paragraaf klopt met de code.
- Inhoudelijk verifieren dat `Red-then-green: yes` daadwerkelijk gebeurde.
- Inhoudelijk verifieren of `Cucumber: applicable` echt cucumber-tests draait.

Het schema dwingt **structurele eerlijkheid** af, niet **inhoudelijke**. Voor de inhoudelijke laag levert slice 9 (test-runner cache) extra: een lokale cache van recente test-runs (`~/.claude/var/gitgit-test-runs.log`) bevat tuples van `(spec_path, working_tree_sha_at_run, exit_code, timestamp)`. De `commit-body.sh` raadpleegt deze cache: een `Tests:` trailer-pad moet matchen tegen een entry met `exit_code = 0` waarvan de timestamp jonger is dan een drempel (default: 10 minuten). Een `/gitgit:saw-red <path>` commando logt het rood-zien expliciet voor `Red-then-green: yes` validatie.

Wat slice 9 wel toevoegt: bewijs dat het pad bestaat, dat een groene run heeft plaatsgevonden, en dat een rood-zien-event gelogd is. Een verzonnen test-pad zonder cache-entry faalt nu de check. Wat slice 9 NIET sluit: de cache bewijst dat het pad recent groen was, maar bewijst niet dat de run plaatsvond op dezelfde diff die nu gecommit wordt. Tree-SHA matching via `git write-tree` is gepland (de `working_tree_sha_at_run` veld in de cache laat een `commit-body.sh` toe om de huidige `git write-tree` output te vergelijken met de waarde uit de cache, en waarschuwen bij mismatch), maar staged-tree veranderingen tussen run en commit blijven onbestreden. De structurele grens uit sectie 3.5 ("inhoudelijk verifieren dat de tests groen zijn op exact deze diff") blijft bestaan; slice 9 verkleint het gaming-oppervlak, niet sluit het volledig.

Implementatie-overhead: `lib/test-cache.sh` met `record_run`, `query_run`, `query_red`, allemaal testbaar met BATS. Test-runners kunnen via een wrapper-skill (`/gitgit:run-spec <path>`) die de run uitvoert en het resultaat logt. Bestaande RSpec/Jest/Go-test runners hoeven niet aangepast te worden.

### 9.5 Andere open vragen

- **Gedeelde hook-lib tussen dont-do-that en gitgit.** Beide gebruiken `dd_emit_*` helpers. Optie A: dupliceer (eenvoudig, dont-do-that en gitgit blijven onafhankelijk). Optie B: extract naar een derde plugin (`leclause-hook-common`?). Voorstel: dupliceer initieel, vermijd premature abstractie. Refactor naar gedeelde lib zodra een derde plugin de helpers gaat hergebruiken of zodra een bug-fix in beide plugins parallel gepatched moet worden. Concrete trigger: na drie geobserveerde sync-bugs of bij toevoeging van een vierde plugin met dezelfde helpers.
- **Versiebump policy.** Plugin-versies in dit repo zijn `1.0.{commits}` (auto via pre-commit hook). Een grote functionele toevoeging zou conventioneel een minor bump zijn. Voorstel: wijzig het auto-versie-script om bij plugin.json `description` updates handmatig minor te kunnen bumpen via een convention (bv. `version: 1.1.0` handmatig zetten en het script honoreert tot de volgende minor of major). Tot dat geregeld is, accepteer patch-only versies.
- **Commit-rule rotation rules.** Van de 14 rules in commit-rule.sh zijn er meerdere die niet over de commit-message zelf gaan (rule 13 "Nooit squash merge", rule 14 "Amend is verboden tenzij..."). Voorstel: tijdens slice 2 splitsen we deze rules naar dedicated guards (`squash-merge-guard.sh`, `amend-guard.sh`) die op de juiste git-commands triggeren in plaats van op `git commit`. Rotation-set wordt gereduceerd tot rules die wel over de commit-message gaan.
- **dont-do-that en gitgit beide hooken op PreToolUse:Bash.** Order is bepaald door plugin-registratie-volgorde. Test in slice 2 met dedicated fixture: een commit die zowel dont-do-that's compliance-guard triggert als gitgit's commit-body-guard. Verifieer dat blokkeren door de ene de ander niet breekt en dat de error-messages stapelbaar zijn.
- **Cross-platform shebang.** De marketplace eist `#!/usr/bin/env node` of `#!/usr/bin/env python3` voor consumer-facing scripts onder `bin/`. Hooks onder `packages/<plugin>/hooks/` en `packages/<plugin>/skills/<skill>/` zijn niet hook-checked; bash is daar toegestaan. Dit plan plaatst alle hooks onder die paden, dus bash is OK. Voor de install-skill onder `skills/install-hooks/lib/install.sh`: ook bash, identieke conventie.
- **Claude Code PreCommit-event afwezig.** https://github.com/anthropics/claude-code/issues/4834 is door Anthropic gesloten als "not planned". De PreToolUse:Bash matcher en de post-commit `--no-verify` detection zijn dus de definitieve oplossingen, geen tijdelijke werkwijzen. Geen toekomstige refactor verwacht uit Claude Code's kant.

## 10. Stapsgewijs implementatieplan (vertical slices)

Het plan eet zijn eigen dogfood: elke slice is een werkende deelverzameling van het complete eindontwerp, niet een afgekapte minimum-uitvoering. Het scope-totaal van slices 1 t/m 9 IS het plan; geen verstopte "later" buiten deze lijst. Volgorde dient verificatie en isolatie: elk slice landt op een staat die testable en zelfstandig valuabel is, en bouwt voort zonder eerdere slices te ondergraven.

Verifiable acceptance per slice betekent: BATS unit-tests voor elk validator-stuk, integratie-tests met fixture-repos voor de hook-paden, manual smoke-test in een wegwerp-repo, en een logbook-entry in de leclause-skills repo `plans/vertical-slice-commit-discipline-progress.md` (per slice toegevoegd in dezelfde commit).

### Slice 1: hook-skelet + gedeelde validator-bibliotheek

Doel: `packages/gitgit/hooks/dispatch.sh`, `packages/gitgit/hooks/hooks.json`, `packages/gitgit/hooks/lib/emit.sh`, `packages/gitgit/hooks/lib/validate-body.sh` met de complete validatie-logica uit sectie 5.5 + 6.6. `validate-body.sh` is op zichzelf compleet en testable. `dispatch.sh` registreert maar dispatcht nog naar geen guards.

Verificatie:
- BATS suite voor `validate-body.sh`: minimaal 30 test-cases die elke regel uit sectie 5.5 dekken plus de skip-patterns uit sectie 6.7.
- Smoke-test: `git commit -m "test"` in wegwerp-repo gaat door, dispatch logt run.
- Plugin laad-fout in een verse Claude-sessie wordt zichtbaar.

### Slice 2: commit-subject + commit-format migreren met test-pariteit

Doel: verhuis `commit-rule.sh` (hernoemd `commit-subject.sh`) en `commit-format.sh` van `dont-do-that` naar `gitgit/hooks/guards/`. `dont-do-that/hooks/dispatch.sh` verwijdert deze guards uit zijn dispatch. State-file `~/.claude/var/commit-rule-state` migreert naar `~/.claude/var/gitgit-commit-rule-state` met een eenmalig migratie-script in `dispatch.sh` (idempotent: detecteert oude file, kopieert, verwijdert oude).

Verificatie:
- De bestaande dont-do-that test-suite voor commit-rule en commit-format wordt mee-verhuisd en draait groen tegen gitgit-locatie.
- Side-by-side test: 10 commits via Claude in een wegwerp-repo voor en na de migratie produceren identiek gedrag.
- Geen guard duplicate-fires: gitgit en dont-do-that registreren beide PreToolUse:Bash; orde van uitvoer en non-interferentie gevalideerd in een dedicated test-fixture.

### Slice 3: commit-body guard in shadow-mode op de leclause-skills repo zelf

Doel: `commit-body.sh` is actief, roept `validate-body.sh` aan, maar emit `dd_emit_pre_context` (warn, niet block). Shadow-mode draait expliciet alleen op de leclause-skills repo zelf (gedetecteerd via `git config remote.origin.url` matching) zodat de operator de regels op zijn dagelijkse meta-werk ervaart zonder andere projecten te raken. False positives en gaming-pogingen worden gelogd naar `~/.claude/var/gitgit-shadow.log` voor latere analyse.

Verificatie en exit-criteria:
- Minimaal 14 dagen kalendertijd EN minimaal 30 commits in `~/.claude/var/gitgit-shadow.log` voordat slice 4 transitioneert.
- False-positive rate van warn-events onder 15% tegen handmatig-gelabelde ground-truth. De labeling wordt versneld via een `bin/audit-shadow-log` helper-script dat per warn-event de commit-SHA, het body, en de kandidaat-violation toont; de operator labelt true / false met een single-key prompt. Per 30 events is dit naar verwachting onder de 15 minuten werk.
- Hogere FP-rate triggers een herziening van trivial-threshold of opt-out enum vóór slice 4 start; geen automatische doorrol.
- Geen Claude-flow gebroken in de shadow-periode (commits gaan altijd door, alleen warn). Gemeten via een `bin/audit-shadow-claude-blocks` script dat detecteert of een commit alsnog mislukt is door de guard.

### Slice 4: block-mode, plus uitrol naar alle Claude-aangedreven repos

Doel: `commit-body.sh` schakelt naar `dd_emit_deny` op alle repos. Trivial-commit detectie (1 file, max 5 insertions) is opt-out. Engine-versie van error-messages: noemt exact de ontbrekende trailer, een gevuld voorbeeld op basis van staged diff, en de Slice opt-out enum.

Verificatie:
- Een commit zonder body op een non-trivial diff wordt geblokkeerd; error-message bevat (a) ontbrekende key, (b) voorbeeld met staged-paden, (c) lijst opt-out tokens.
- Een trivial-commit zonder body gaat door.
- BATS-suite uitgebreid met block-mode test-cases en een fuzzing-test op pathologische bodies.

### Slice 5: user-level git hooks absorberen

Doel: `~/.claude/hooks/block-coauthored-trailer.sh` is geabsorbeerd in `gitgit/hooks/guards/commit-trailers.sh` met identiek of strenger gedrag (Co-Authored-By blokkeren tenzij `Co-Authored-By: <user-eigen email>`). `~/.claude/hooks/warn-untested-commits.sh` is geabsorbeerd in `commit-body.sh` (de Tests-trailer-eis dekt hetzelfde, harder). `~/.claude/hooks/block-git-dash-c.sh` verhuist 1-op-1 naar `gitgit/hooks/guards/git-dash-c.sh`. `~/.claude/settings.json` opgeschoond. CLAUDE.md update: pointer naar `/gitgit:commit-discipline`, oude regels die nu gehandhaafd worden ingekort tot één-regel referenties.

Verificatie:
- Bestaande gedrag: Co-Authored-By geblokkeerd, git -C geblokkeerd; identieke error-messages of explicit verbeteringen-changelog.
- ~/.claude/hooks/ bevat na deze slice nog alleen: `auto-format.sh` (PostToolUse, geen git), `block-autonomous-backlog-issues.sh` (PreToolUse Bash gh, geen git).
- Test: in een verse Claude-sessie zonder gitgit installed, gaan deze guards niet meer af; met gitgit installed: zelfde gedrag als voorheen.

### Slice 6: `/gitgit:install-hooks` skill voor git-native enforcement

Doel: SKILL.md plus install-script. Detecteert `core.hooksPath`, kopieert `commit-msg`, `prepare-commit-msg`, `pre-push`, en `post-commit` scripts. Conflict-detectie: weigert te overschrijven zonder `--force` als er al hooks zijn, met diff-preview. Idempotent: tweede aanroep is no-op.

Verificatie:
- BATS test-fixture met (a) lege repo, (b) repo met bestaande commit-msg, (c) repo met `core.hooksPath` configured, (d) repo onder `git worktree`. Alle vier scenario's correct afgehandeld.
- Manual: in een test-repo plaatst `/gitgit:install-hooks` de scripts; een commit zonder body via plain `git commit -m "..."` (buiten Claude) wordt geblokkeerd; `--no-verify` skipt; `# vsd-skip: <reason>` skipt en logt.
- Cross-platform smoke-test: install-script werkt op macOS, Linux, en Windows met Git for Windows (via WSL test-runner).

### Slice 7: pre-push wip-gate

Doel: `push-wip-gate.sh` (PreToolUse:Bash op `git push`) plus de git-native `pre-push` hook (geinstalleerd door slice 6). Beide leunen op een gedeelde `lib/wip-gate.sh` die de te-pushen range parseert en controleert.

Verificatie:
- BATS test-cases voor (a) range zonder wip-commits, (b) range met één wip-commit, (c) range met expliciete `GITGIT_ALLOW_WIP_PUSH=1`, (d) push naar een upstream die nog niet bestaat (initial push), (e) `--force-with-lease`.
- Manual: wip-commit pushen zonder flag faalt; met flag gaat door en logt naar `~/.claude/var/gitgit-wip-pushes.log`.

### Slice 8: prepare-commit-msg template-fill

Doel: `prepare-commit-msg` git-hook (geinstalleerd door slice 6) detecteert staged file types via `git diff --cached --name-only` en pre-vult de body-template. Slice-suggestie via een classifier die paden mapt naar layer-tokens (`spec/` -> "spec", `app/controllers/` -> "backend", `app/javascript/` -> "frontend", `db/migrate/` -> "migration"). Tests-trailer pre-vult met spec-paden uit de staged diff.

Verificatie:
- BATS test-fixture: een staged diff met paden uit elk van de detecteerbare layers krijgt de correcte template.
- Manual: `git commit` in een test-repo opent een editor met de template gevuld; auteur kan accepteren, aanpassen, of overschrijven; commit-msg validatie aan het eind blijft authoritative.
- Test dat de skill-friction zichtbaar daalt: 10 representatieve commits door een Claude-sessie genereren met en zonder template-fill, vergelijk gemiddelde aantal trailer-edits.

### Slice 9: test-runner cache voor `Tests:` validatie

Doel: `lib/test-cache.sh` met `record_run`, `query_run`, `query_red`. `/gitgit:run-spec <path>` skill als wrapper rond RSpec/Jest/Go-test/etc. die de run uitvoert en result logt. `commit-body.sh` raadpleegt de cache: een `Tests:` pad zonder recente groene run faalt validatie. `Red-then-green: yes` vereist een matchende rood-entry in de cache van vóór de groen-entry. Sluit het dictation-gat aanmerkelijk.

Verificatie:
- BATS test-cases voor cache-write, cache-read, expiration (default 10 min), tree-SHA matching.
- Integratie-test: een Claude-flow `1) /gitgit:run-spec spec/foo.rb (rood) 2) edit 3) /gitgit:run-spec spec/foo.rb (groen) 4) git commit met Tests: spec/foo.rb en Red-then-green: yes` slaagt; same flow zonder stap 1 faalt validatie.
- Performance: cache-lookup voegt minder dan 100ms toe aan commit-validatie.

### Slice 10: documentatie, marketplace-tabel, en operator-onboarding

Doel: `packages/gitgit/skills/commit-discipline/SKILL.md` (volledig schema-document, voorbeelden, escape-hatches, troubleshooting). `packages/gitgit/README.md` uitbreiden met een commit-discipline sectie. Top-level `README.md` van leclause-skills update gitgit-rij. CLAUDE.md krijgt een pointer en de oude verspreide regels worden ingekort. `~/.claude/recursion/plans/2026-04-30-gitgit-vertical-slice-commit-body.md` wordt bijgewerkt met implementatie-state na voltooiing van elk slice. Een `/gitgit:saw-red <path>` en `/gitgit:run-spec <path>` skill-handleiding voor de operator.

Verificatie:
- Een verse Claude-sessie kan met enkel `/gitgit:commit-discipline` het volledige schema beschrijven.
- Een nieuwe collega-developer kan via README in 5 minuten een werkende install krijgen op een verse repo.
- De leclause-skills repo heeft 0 commits zonder body-schema na slice 4 (gemeten via een audit-script over de mission-branch).

## 11. Recursion plan stub

Het plan wordt parallel opgeslagen als atomic improvement in `~/.claude/recursion/plans/2026-04-30-gitgit-vertical-slice-commit-body.md`, zodat de nightly improvement loop het kan oppakken voor implementatie. De recursion-plan-vorm is condensed (Wat / Waarom / Bron / Wie / Auto-loop context). Zie sectie 9 van de recursion research SKILL voor het schema.

---

> **Pride check vereist voor STOW.** Dit document is een artefact dat door `/autonomous:pride` moet voor het van de rover af gaat. Open punten in sectie 9 zijn bewust open gelaten voor pride-review en operator-input.
