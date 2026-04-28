---
name: merge-to-default
description: Use when the user wants to land the current branch on the project's default branch with a github-style merge commit. Triggers on /gitgit:merge-to-default, "merge naar default", "merge to main", "merge this into main". Commits any pending work via commit-all-the-things first, produces a --no-ff merge commit, and rebases the source branch on conflict before retrying.
allowed-tools: Bash(git symbolic-ref:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git checkout:*), Bash(git merge:*), Bash(git rebase:*), Bash(git log:*), Bash(git diff:*), Bash(git ls-remote:*), Bash(git remote:*)
---

# /gitgit:merge-to-default

Land the current branch on the project's default branch with a real `--no-ff` merge commit, the same shape GitHub's merge button produces. Pending working-tree changes ride along via `gitgit:commit-all-the-things`. On a conflict the source branch is rebased on the latest default and the merge is retried so the final state is a clean merge commit on top of an up-to-date default.

## Wanneer

- De huidige feature-branch is af en moet op `main` (of `master`) landen
- De user typt `/gitgit:merge-to-default` of zegt "merge naar default", "merge to main", of "merge this into main"
- Lokale workflow zonder PR-stap: het project doet trunk-based development of accepteert directe merges op de default branch

Niet voor remote-merges: deze skill produceert alleen lokale commits en pushed niet. Push gaat via een aparte expliciete user-actie.

## Stap 0: Detecteer default branch en huidige branch

### 0a: Default branch naam

Bepaal de naam van de default branch (`$DEFAULT`):

1. Probeer `git symbolic-ref refs/remotes/origin/HEAD` en pak het laatste pad-segment (bijv. `main`).
2. Lukt dat niet (geen remote, of de ref is niet gezet), kijk lokaal: `git rev-parse --verify refs/heads/main` en `git rev-parse --verify refs/heads/master`. Voorkeur voor `main` als beide bestaan.
3. Bestaat geen van beide, stop met de melding: `Cannot determine the default branch. Set origin/HEAD via `git remote set-head origin --auto` or create a local main/master.`

### 0b: Huidige branch

```bash
CURRENT=$(git symbolic-ref --short HEAD)
```

Als `git symbolic-ref --short HEAD` faalt (detached HEAD), stop met de melding: `HEAD is detached. Switch to a branch before invoking /gitgit:merge-to-default.`

## Stap 1: No-op safeguard wanneer al op default

Als `$CURRENT` gelijk is aan `$DEFAULT`, doe niets. Toon een duidelijke TUI-waarschuwing en stop:

```
⚠  /gitgit:merge-to-default is a no-op on the default branch itself.
    Current branch: <DEFAULT>
    There is nothing to merge into <DEFAULT> from <DEFAULT>.

    Switch to the feature branch you want to merge first, then re-run
    /gitgit:merge-to-default.
```

Geen commit, geen merge, geen rebase. Exit cleanly.

## Stap 2: Pending werk wegcommitten via commit-all-the-things

Run `git status --porcelain`. Niet leeg → er is uncommitted werk op de feature-branch dat moet meeliften op de merge.

Invoke `gitgit:commit-all-the-things` via de Skill tool. Die sub-skill groepeert alle uncommitted wijzigingen in logische commits volgens de project- en user-CLAUDE.md conventies en commit ze op de huidige branch (`$CURRENT`). Wacht tot die skill klaar is voor je verder gaat.

Na de invocatie: `git status --porcelain` is leeg, anders stop met de melding `commit-all-the-things left uncommitted changes; investigate before merging.`

## Stap 3: First-pass merge

```bash
git checkout $DEFAULT
git merge --no-ff --no-edit $CURRENT
```

`--no-ff` dwingt een merge commit af (twee parents), zelfs als de default branch precies achter de feature-branch zit. Zo krijgt de geschiedenis dezelfde vorm als wat GitHub's "Create a merge commit" knop produceert.

`--no-edit` houdt de auto-gegenereerde merge subject (`Merge branch '<CURRENT>'`), dezelfde vorm die GitHub's merge button gebruikt.

- **Slaagt schoon:** door naar Stap 5.
- **Conflicten:** door naar Stap 4.

## Stap 4: Conflict-pad via rebase

Wanneer de merge in stap 3 conflicten geeft, zit de source branch achter op de default of werd hetzelfde stuk code aan beide kanten gewijzigd. De skill kiest hier ALTIJD voor `rebase first, retry merge` boven handmatige conflictoplossing in een merge commit, omdat de uiteindelijke geschiedenis dan een clean merge commit op een actuele default toont.

```bash
git merge --abort
git checkout $CURRENT
```

Invoke `gitgit:rebase-latest-default` via de Skill tool. Die sub-skill rebased `$CURRENT` op de freshest `$DEFAULT` (lokaal of `origin/$DEFAULT`, whichever is ahead) en lost trivial conflicts (whitespace, identieke edits, lockfile regenerations) automatisch op. Voor genuine ambiguïteiten stopt rebase-latest-default en surface die naar de user.

Na een geslaagde rebase: keer terug naar Stap 3 voor de retry.

```bash
git checkout $DEFAULT
git merge --no-ff --no-edit $CURRENT
```

Nu zou de merge schoon moeten verlopen. Faalt-ie nog steeds, surface de conflict en stop; dat betekent dat de rebase niet alle ambiguïteit kon oplossen en de user moet handmatig ingrijpen.

## Stap 5: Rapportage

Toon een korte samenvatting van wat er gebeurd is:

```
✓ Merged <CURRENT> into <DEFAULT>
  Merge commit: <abbrev SHA>
  Files changed: <N>, +<INS> -<DEL>
  Rebase preceded merge: yes/no
```

`<abbrev SHA>` komt uit `git rev-parse --short HEAD`. `Files changed`, insertions en deletions uit `git diff --shortstat $DEFAULT~1...$DEFAULT`.

Push gebeurt NIET in deze skill. Een push naar de remote is een aparte user-go (de user-CLAUDE.md push-regime documenteert dit). De gebruiker pusht zelf wanneer hij gevalideerd heeft dat de merge klopt.

## Regels

- **`--no-ff` is verplicht.** Geen fast-forward, geen squash. De merge commit bewaart twee parents zodat reviewers de iteratie op de feature-branch terug kunnen lezen.
- **No-op-on-default is een hard safeguard, geen waarschuwing-en-doorgaan.** Wanneer `$CURRENT == $DEFAULT` doet de skill niets en exit cleanly. De TUI-waarschuwing legt uit wat er moet gebeuren (switch naar feature branch).
- **Pending werk eerst committen, niet stashen.** `commit-all-the-things` produceert echte commits in de geschiedenis. Stashing zou werk verbergen tot na de merge en gaat tegen de transparantie van de skill in.
- **Op conflict altijd rebase, nooit handmatige merge resolution.** De skill produceert óf een clean merge commit, óf surfaced de conflict aan de user. Een merge commit met handmatige resolutie verbergt de iteratie die de feature-branch had moeten plaatsen.
- **Nooit pushen.** Push is een aparte user-actie.
