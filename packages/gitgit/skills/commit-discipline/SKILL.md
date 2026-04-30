---
name: commit-discipline
user-invocable: true
description: >
  Reference skill for the gitgit commit body schema: subject + WHY
  paragraph + Slice / Tests / Red-then-green trailers parsed via
  git interpret-trailers, with opt-out enum tokens and an evidence
  cache that backs the trailer claims. Read this skill when the
  hook denies a commit and you want the canonical schema, examples,
  escape-hatches, and troubleshooting.
argument-hint: ""
---

# /gitgit:commit-discipline

Canonieke referentie voor het gitgit commit body schema. De PreToolUse:Bash
guard en de git-native hooks (`commit-msg`, `pre-push`) lezen dezelfde
validator (`hooks/lib/validate-body.sh`); dit document beschrijft wat die
validator eist, welke ontsnappingsluiken bestaan, en hoe je troubleshoot.

## Wat

De commit-discipline extensie dwingt een gestructureerde commit body af via
twee lagen: een PreToolUse:Bash guard die Claude-aangedreven commits
onderschept, en git-native hooks (geinstalleerd via `/gitgit:install-hooks`)
die commits buiten Claude om bewaken.

Het schema bestaat uit drie onderdelen: een onderwerp-regel in imperatief
Engels (50/72 tekens), een vrije WHY-paragraaf die uitlegt waarom de
wijziging nodig is, en een reeks trailers in `git interpret-trailers`-formaat
(`Key: Value`, onderaan het bericht). De validator draait in twee lagen maar
deelt exact dezelfde logica, zodat gedrag nooit divergeert.

Claude Code biedt geen native PreCommit lifecycle event
(https://github.com/anthropics/claude-code/issues/4834, closed not planned),
dus de twee-laagse architectuur is definitief, niet voorlopig.

## Het schema

### Onderwerpregels

- Imperatief Engels ("Add handler", niet "Added handler" of "Adding handler").
- Maximaal 72 tekens; 50 tekens is het streefdoel voor leesbaarheid in `git log`.
- Geen punt aan het einde.
- Geen conventionele-commits-prefix verplicht (`feat:`, `fix:`), maar toegestaan.
- Automatisch overgeslagen voor: `Merge ...`, `Revert ...`, `fixup!`, `squash!`, `amend!`.
- Cherry-pick commits: skip loopt via twee lagen. De git-native `commit-msg`
  hook detecteert cherry-picks omdat `git cherry-pick -x` de frase
  `(cherry picked from commit <sha>)` aan de body toevoegt. De PreToolUse
  guard detecteert dezelfde frase wanneer Claude een `git commit -m '...(cherry
  picked from commit ...)...'`-wrapper aanroept. Een raw `git cherry-pick` vanuit
  de terminal passeert PreToolUse niet, dus de laag-splitsing is daar niet van
  toepassing. Zonder de `-x` vlag bevat de subject geen `(cherry picked...)`
  frase, waardoor de anti-copy-paste check ten onrechte kan vuren als de WHY
  van de bron-commit identiek is.

### WHY-paragraaf

- Vrije proza, minimaal twee niet-lege regels OF minimaal 60 tekens eindigend
  op `.`, `!` of `?`.
- Staat na de onderwerpregel, gescheiden door een lege regel.
- Anti-copy-paste: de SHA1 van de WHY-tekst mag niet identiek zijn aan die van
  een van de vijf meest recente commits op de huidige branch.
- Wordt niet inhoudelijk gevalideerd (te makkelijk te bullshitten), wel
  structureel.

### Verplichte trailers

| Trailer | Waarde | Verplicht bij |
|---------|--------|---------------|
| `Slice` | opt-out token of vrije tekst (zie hieronder) | altijd |
| `Tests` | comma-gescheiden lijst spec-paden | als `Slice` geen opt-out token is |
| `Red-then-green` | `yes` of `n/a (reden >= 10 chars)` | als `Slice` niet `docs-only`, `config-only`, `migration-only`, `spec-only`, of `chore-deps` is |

**`Slice`-regels:** de waarde is ofwel een van de acht opt-out tokens (zie
volgende sectie), ofwel vrije tekst die beschrijft welke lagen de commit raakt
(bijv. `handler + service + spec`, `frontend + backend + migration`).

**`Tests`-regels:** elk pad in de lijst moet bestaan in de HEAD-tree
(`git ls-tree -r HEAD --name-only`) of in de staged diff
(`git diff --cached --name-only`). Ondersteunde extensies:
`.rb`, `.py`, `.js`, `.ts`, `.go`, `.sh`, `.bash`, `.feature`, `.tsx`, `.jsx`.
Anker-suffixen (`#method_name`) worden gestript voor de bestandscontrole.

**`Red-then-green`-regels:** waarde `yes` betekent dat de test echt in rode
staat gezien is. Waarde `n/a (reden)` is toegestaan met een rationale van
minimaal 10 tekens. Kale `n/a` zonder rationale is afgewezen.

### Optionele trailers

| Trailer | Waarde |
|---------|--------|
| `Resolves` | URL naar issue, Sentry, incident; of `none` |
| `Cucumber` | `applicable` (en gebruikt), of `n/a (reden)` |
| `Co-authored-by` | toegestaan mits niet `@anthropic.com`-adres (zie escape-hatches) |

Trailers worden geparsed via `git interpret-trailers --parse`. Volgorde
binnen de trailer-block maakt niet uit.

## Opt-out enum

Als `Slice` een van deze acht tokens is, gelden versoepelde regels:

| Token | Wanneer te gebruiken |
|-------|----------------------|
| `docs-only` | Alleen wijzigingen in documentatie (`.md`, `.txt`, `.rst`, README) |
| `config-only` | Alleen wijzigingen in configuratiebestanden zonder gedragswijziging |
| `migration-only` | Alleen database-migraties zonder bijbehorende handler/spec wijziging |
| `spec-only` | Commit bevat uitsluitend spec/test-bestanden (de diff is zelf het rode bewijs) |
| `chore-deps` | Dependency-bumps, lockfile-updates, build-systeem tweaks |
| `revert` | Volledige revert van een eerdere commit |
| `merge` | Merge-commits (gewoonlijk automatisch aangemaakt) |
| `wip` | Work-in-progress commit op een feature-branch; **blokkerd bij push** |

Bij `docs-only`, `config-only`, `migration-only`, `spec-only`, en `chore-deps`
vervalt ook de `Red-then-green`-verplichting. Rationale: migraties hebben geen
betekenisvolle rood-dan-groen sequentie; spec-only commits zijn zelf de rode
fase (de spec bestond eerder dan de implementatie). Bij alle acht vervalt de
`Tests`-verplichting.

`wip`-commits worden geaccepteerd op commit-tijd maar geblokkeerd door de
pre-push gate. Je kunt niet per ongeluk een wip-commit naar remote sturen.

## Voorbeelden

### Voorbeeld 1: feature commit met handler + service + spec + Red-then-green

```
Drop invalid meter reading on transaction events

When StartTransaction or StopTransaction messages arrive with a
meter reading that fails domain validation, we previously rejected
the entire event, which masked session starts and stops in analytics.
This change keeps the transaction event but discards just the bad
reading, restoring the visibility we lost.

Tests: spec/services/session_spec.rb#start_event_with_bad_reading,
       spec/services/session_spec.rb#stop_event_with_bad_reading
Slice: handler + service + spec
Red-then-green: yes
Resolves: https://example.org/backlog/issues/1234
```

### Voorbeeld 2: docs-only opt-out met minimale trailers

```
Update install instructions for Windows consumers

The symlink-free layout means Windows users need cp -f instead of
ln -s. The previous instructions silently created a text file.

Slice: docs-only
```

(Geen `Tests` of `Red-then-green` vereist bij `docs-only`.)

### Voorbeeld 3: chore-deps versie-bump

```
Bump bundler to 2.5.18

Security patch for CVE-2026-XXXX. No behavior change expected;
suite still loads without modification.

Tests: spec/spec_helper.rb
Slice: chore-deps
Red-then-green: n/a (no behavior change)
```

### Voorbeeld 4: migration-only opt-out

```
Add NOT NULL constraint to sessions.user_id

The column was introduced in a prior migration without the constraint.
A backfill confirmed no null rows exist in production before this runs.

Slice: migration-only
```

(Geen `Tests` of `Red-then-green` vereist bij `migration-only`.)

### Voorbeeld 5: spec-only opt-out

```
Add failing specs for enrollment race-condition fix

Tests written first to drive the implementation. The handler does not
exist yet; these specs are the red phase.

Slice: spec-only
```

(Geen `Tests` of `Red-then-green` vereist bij `spec-only`.)

### Voorbeeld 6: wip commit (en de pre-push gate die hem tegenhoudt)

```
Sketch enrollment race-condition fix

Half-baked: the locking strategy is not settled yet. Saving state
before context switch.

Slice: wip
```

Dit commit gaat lokaal door. Een `git push` met dit commit in de range
wordt geblokkeerd door de pre-push gate met:

```
wip-gate: commit <sha> has Slice: wip in push range
Set GITGIT_ALLOW_WIP_PUSH=1 or add '# allow-wip-push' to bypass.
```

## Escape-hatches

### `# vsd-skip: <reden>` in de commit body

Voeg een commentaarregel toe aan de body (begint met `#`):

```
Fix typo in error message

# vsd-skip: trivial one-char fix, full schema not warranted
```

De validator leest de commentaarregels (voor het strippen) en
logt de reden naar `~/.claude/var/gitgit-skips.log`. De commit
gaat door. De reden mag niet leeg zijn.

### `--no-verify`

`git commit --no-verify` slaat alle git-native hooks over. De PreToolUse:Bash
guard onderschept dit patroon niet (de flag is in de command-string, niet een
aparte hook). De post-commit hook logt `--no-verify`-gebruik naar
`~/.claude/var/gitgit-no-verify.log` voor achteraf auditing.

**Race-window beperking:** de detector gebruikt een trace-venster van 30
seconden. Gelijktijdige commits in een andere shell kunnen de trace verversen
en een bypass in deze shell maskeren. Lange test-runs (>30s tussen het starten
van commit-msg en het vuren van post-commit) kunnen false positives opleveren.
Het audit-log is best-effort, niet autoritatief.

### `GITGIT_ALLOW_AI_COAUTHOR=1`

De `commit-trailers.sh` guard blokkeert `Co-Authored-By:` trailers met een
`@anthropic.com`-e-mailadres. Stel `GITGIT_ALLOW_AI_COAUTHOR=1` in om dat
specifieke blokkade te omzeilen (bijv. bij expliciete attributie-vereisten).

### `GITGIT_ALLOW_WIP_PUSH=1` of `# allow-wip-push`

Omzeilt de pre-push wip-gate voor de huidige push. Beide vormen worden gelogd
naar `~/.claude/var/gitgit-wip-pushes.log`. Gebruik de magic-comment-vorm
als je de bypass in de command zelf wilt documenteren zonder een omgevingsvariabele
te exporteren.

**Asymmetrie:** het `# allow-wip-push` magic comment werkt alleen wanneer
Claude de push uitvoert (de PreToolUse:Bash guard leest de bash-commandstring).
Voor pushes die je zelf in een terminal uitvoert werkt alleen
`GITGIT_ALLOW_WIP_PUSH=1`; de git-native pre-push hook leest de
commandstring niet.

### `GITGIT_TRIVIAL_OK=1`

Wordt automatisch gezet door de PreToolUse:Bash guard als de staged diff
maximaal 1 bestand en maximaal 5 inserties telt. Kan ook handmatig
gexporteerd worden om body-validatie voor een specifiek triviaal commit
over te slaan. Niet persistent; geldt alleen voor de eerstvolgende commit.

**Beperking:** handmatige export van `GITGIT_TRIVIAL_OK=1` geldt alleen voor de
PreToolUse:Bash laag. De git-native commit-msg hook leidt de trivial-flag
opnieuw af uit de staged diff bij elke run; een extern geexporteerde waarde
bypascht die hook niet. Gebruik voor triviale-maar-grotere commits op de
git-native laag het `# vsd-skip: <reden>` magic comment in plaats van de
environment variable.

### `GITGIT_TEST_CACHE_REQUIRED=1`

Standaard uitgeschakeld. Als je dit op `1` zet, moet elk pad in de
`Tests:`-trailer een recente groene run in de test-runner cache hebben
(`~/.claude/var/gitgit-test-runs.log`). Gebruik `/gitgit:run-spec` om
runs te loggen en `/gitgit:saw-red` om handmatig een rode observatie te
registreren.

## Troubleshooting

**"De hook blokkeert mijn commit met missing-tests; hoe los ik dat op?"**

De `Tests:`-trailer ontbreekt of bevat geen geldig pad. Voeg een
`Tests:`-regel toe met de paden van de specs die je gerund hebt, bijv.:

```
Tests: spec/services/enrollment_spec.rb, spec/models/device_spec.rb
```

De paden worden gecontroleerd tegen de HEAD-tree en de staged diff. Zorg
dat de bestanden echt bestaan in het project. Als er geen tests zijn (bijv.
pure config-wijziging), gebruik dan een passend opt-out token:
`Slice: config-only`.

**"Mijn body is wel duidelijk maar de hook zegt why-too-short"**

De WHY-paragraaf is te compact. De validator eist minimaal twee niet-lege
regels OF minimaal 60 tekens eindigend op `.`, `!`, of `?`. Een
eenregelige samenvatting van 30 tekens voldoet niet. Breek de zin op
in twee regels of schijf een volledigere verklaring.

**"Ik krijg duplicate-why; ik heb mijn body zelf geschreven"**

De SHA1 van jouw WHY-tekst (na whitespace-normalisatie) matcht precies
die van een van de vijf meest recente commits op de huidige branch. Dit
wijst op copy-paste van een eerder commit-bericht. Herschrijf de WHY voor
dit specifieke commit; zelfs kleine tekstuele afwijkingen zijn voldoende.

**"tests-cache-miss op een pad dat ik echt heb gerund"**

De cache-check is opt-in via `GITGIT_TEST_CACHE_REQUIRED=1`. Als die
variabele niet gezet is, wordt de cache nooit geraadpleegd en krijg je
deze fout niet. Is de variabele wel gezet, dan is er geen cache-entry
gevonden voor het pad. Gebruik `/gitgit:run-spec <pad>` om een run te
loggen, of exporteer `GITGIT_TEST_CACHE_REQUIRED=0` voor dit commit.

**"red-then-green-evidence-missing terwijl ik echt rood heb gezien"**

De cache bevat geen RED-entry voor het pad dat voorafgaat aan de groene run.
Gebruik `/gitgit:saw-red <pad>` om handmatig een rode observatie te
registreren, daarna `/gitgit:run-spec <pad>` voor de groene run. De
combinatie satisfies `Red-then-green: yes` validatie.

**"push geblokkeerd door wip-gate maar de wip-commit is al geamend"**

Als je een `Slice: wip` commit hebt geamend naar een normaal schema-compliant
commit, loopt de wip-gate soms over een stale reflog-entry. Controleer met
`git log --oneline` of er nog een `Slice: wip` commit in de push-range zit.
Als er geen meer is maar de gate nog blokkeert, stel `GITGIT_ALLOW_WIP_PUSH=1`
in voor de push en meld de edge-case.

## Architectuur

De enforcement bestaat uit twee parallelle lagen die dezelfde
`hooks/lib/validate-body.sh` aanroepen:

```
git commit (via Claude Code)
    |
    v
PreToolUse:Bash dispatcher (hooks/dispatch.sh)
    |-- git-dash-c.sh       (blokkeert git -C <dir>)
    |-- commit-format.sh    (editor-mode detectie)
    |-- commit-subject.sh   (50/72 subject-regels)
    |-- commit-body.sh      (body-schema, trivial-check)
    |-- commit-trailers.sh  (Co-Authored-By @anthropic.com)
    |-- push-wip-gate.sh    (wip-commits bij git push)
    |
    +-> validate-body.sh (gedeelde bibliotheek)
           |-- layer-classify.sh
           |-- example-synth.sh
           |-- wip-gate.sh
           +-- test-cache.sh

git commit (buiten Claude, via CLI of IDE)
    |
    v
git-native hooks (geinstalleerd via /gitgit:install-hooks)
    |-- commit-msg          -> validate-body.sh (zelfde lib)
    |-- prepare-commit-msg  -> layer-classify.sh (template-fill)
    |-- post-commit         (logt --no-verify gebruik)
    +-- pre-push            -> wip-gate.sh
```

De git-native hooks staan in
`packages/gitgit/skills/commit-discipline/git-hooks/` en worden gekopieerd
(niet gesymlinkt) door `install-hooks`.

## Migratie-resterend

De commit-subject en commit-format guards zijn verhuisd vanuit `dont-do-that`
naar `gitgit/hooks/guards/` (slice 2). De user-level git hooks
(`block-coauthored-trailer.sh`, `warn-untested-commits.sh`,
`block-git-dash-c.sh`) zijn geabsorbeerd in `gitgit/hooks/guards/` (slice 5).
`~/.claude/hooks/` bevat geen git-rakende hooks meer na de migratie.

De audit-script zit in de plugin onder `bin/audit-no-body-commits`. Gebruik het
als volgt om het altijd tegen de actieve plugin-versie te draaien:

```bash
GITGIT=$(jq -r '.plugins["gitgit@leclause"][0].installPath' \
  ~/.claude/plugins/installed_plugins.json)
python3 "$GITGIT/bin/audit-no-body-commits"
python3 "$GITGIT/bin/audit-no-body-commits" --branch main --since 2026-04-01
python3 "$GITGIT/bin/audit-no-body-commits" --exclude-trivial
```
