---
name: merge-to-default
description: Use when the user wants to land the current branch on the project's default branch with a github-style merge commit. Triggers on /gitgit:merge-to-default, "merge naar default", "merge to main", "merge this into main". Commits any pending work via commit-all-the-things first, produces a --no-ff merge commit, rebases the source branch on conflict before retrying, and deletes the local source branch after the merge is confirmed (remote branches are left to GitHub workflows).
allowed-tools: Bash(git symbolic-ref:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git checkout:*), Bash(git merge:*), Bash(git rebase:*), Bash(git log:*), Bash(git diff:*), Bash(git ls-remote:*), Bash(git remote:*), Bash(git branch:*), Bash(git worktree:*), Skill(gitgit:commit-all-the-things), Skill(gitgit:rebase-latest-default)
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
    /gitgit:merge-to-default. Run `git branch` to list local branches,
    or `git reflog` to find the branch you were on before HEAD landed
    here.
```

Geen commit, geen merge, geen rebase. Exit cleanly.

## Stap 2: Pending werk wegcommitten via commit-all-the-things

Run `git status --porcelain`. Niet leeg → er is uncommitted werk op de feature-branch dat moet meeliften op de merge.

Invoke `gitgit:commit-all-the-things` via de Skill tool. Die sub-skill groepeert alle uncommitted wijzigingen in logische commits volgens de project- en user-CLAUDE.md conventies en commit ze op de huidige branch (`$CURRENT`). Wacht tot die skill klaar is voor je verder gaat.

Na de invocatie: `git status --porcelain` is leeg, anders stop met de melding `commit-all-the-things left uncommitted changes; investigate before merging.`

**Belangrijk om vooraf te weten:** de skill commit ALLES wat er staat, ook half-afgemaakt werk dat de user nog niet wilde vastleggen. Wie staged of working-tree wijzigingen heeft die niet bij de merge horen, zet die eerst opzij (`git stash push -m "wip"`, of een aparte snipe-commit op een ander branch) voordat `/gitgit:merge-to-default` aanroept. De skill heeft geen opt-out voor stap 2; dat is bewust, omdat een halve-merge met onuitgesproken pending wijzigingen de geschiedenis vertroebelt.

## Stap 3: First-pass merge

```bash
git checkout $DEFAULT
git merge --no-ff --no-edit $CURRENT
```

`--no-ff` dwingt een merge commit af (twee parents), zelfs als de default branch precies achter de feature-branch zit. Zo krijgt de geschiedenis dezelfde vorm als wat GitHub's "Create a merge commit" knop produceert; de iteratie op de feature-branch blijft zichtbaar in `git log --graph`. Een fast-forward of squash merge zou diezelfde iteratie afvlakken, daarom is `--no-ff` hier niet onderhandelbaar. Wie liever een fast-forward of een rebase-merge wil, gebruikt `git merge --ff-only` of `git rebase` direct vanaf de command line; deze skill is specifiek voor de github-merge-button vorm.

`--no-edit` houdt de auto-gegenereerde merge subject (`Merge branch '<CURRENT>'`), dezelfde vorm die GitHub bij een lokale merge gebruikt. Dat is bewust niet de PR-merge subject (`Merge pull request #N from ...`), omdat deze skill geen PR aanmaakt en geen PR-nummer kent.

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

### Wanneer rebase-latest-default zelf op een non-trivial conflict stopt

`gitgit:rebase-latest-default` lost alleen trivial conflicts (whitespace, identieke edits, lockfile regenerations) automatisch op. Voor genuine ambiguïteit stopt die skill mid-rebase en wijst de user op de conflict bestanden. In dat geval is `merge-to-default` ook gestopt: de werktree zit mid-rebase op `$CURRENT`, `$DEFAULT` is onveranderd. De user heeft drie cleanup-opties:

- `git rebase --abort`: zet `$CURRENT` terug naar pre-rebase staat. Geen merge gebeurd. Daarna kan de user de conflict op een andere manier aanpakken.
- Handmatig de conflict resolven, `git rebase --continue` per stap, en dan `/gitgit:merge-to-default` opnieuw aanroepen om de retry-merge uit te voeren.
- `git checkout $DEFAULT` zonder verdere actie: de mid-rebase state op `$CURRENT` blijft staan, `$DEFAULT` is intact, de user beslist later wat te doen.

`merge-to-default` zelf maakt geen van deze keuzes voor de user; mid-rebase met genuine ambiguïteit is precies de plek waar handmatige resolutie de juiste manier is.

## Stap 5: Lokale source-branch opruimen

Na een geconfirmde merge ruimt de skill de lokale `$CURRENT` branch op. Geconfirmd betekent: HEAD zit op `$DEFAULT`, HEAD heeft twee parents, en de tweede parent komt overeen met de huidige tip van de `$CURRENT` ref. De skill checkt dat met:

```bash
SECOND_PARENT=$(git rev-parse HEAD^2 2>/dev/null || true)
SOURCE_TIP=$(git rev-parse "$CURRENT")
[ "$SECOND_PARENT" = "$SOURCE_TIP" ] || stop_with "merge confirmation failed; HEAD^2 ($SECOND_PARENT) does not match $CURRENT tip ($SOURCE_TIP)"
```

(Een `--no-ff` merge op `$DEFAULT` raakt de `$CURRENT` ref niet aan: vóór en na de merge wijst `$CURRENT` naar dezelfde commit. In het rebase-pad rebased Stap 4 `$CURRENT` op `$DEFAULT` en de retry-merge gebruikt die nieuwe tip; `git rev-parse $CURRENT` na de retry-merge geeft die post-rebase tip die ook HEAD^2 op `$DEFAULT` is.)

Wanneer dat klopt: probeer de branch te deleten met `git branch -d "$CURRENT"`. Vóór dat command checkt de skill twee dingen:

1. **Worktree safety.** `git worktree list --porcelain` toont één blok per worktree met `branch refs/heads/<naam>`. Als `$CURRENT` in een ander worktree dan de huidige checked out is (compare met `git rev-parse --git-dir` om de eigen worktree te identificeren), skip de delete en surface een TUI-regel: `⚠  Source branch '<CURRENT>' is checked out in worktree <path>; skipping local branch delete.` De merge commit op `$DEFAULT` blijft intact, alleen de lokale ref van `$CURRENT` blijft staan.

2. **Geen `-D` force.** De skill gebruikt `-d` (lowercase), niet `-D`. `-d` faalt op niet-gemergede branches; in deze flow is `$CURRENT` per definitie gemerged in `$DEFAULT` via de merge commit, dus `-d` slaagt. Mocht `-d` toch falen (race-condition met user-input tussen stap 3/4 en stap 5), surface de error en stop zonder forceren.

Remote branches raakt deze skill niet. De aanname is dat GitHub-workflows (branch protection rules met "delete head branch on merge") of een aparte cleanup-job de remote `origin/<CURRENT>` opruimen wanneer de PR-merge upstream landt. Mocht jouw repo dat niet doen, ruim de remote branch zelf op met `git push origin --delete <CURRENT>` na de push (dat zit niet in deze skill).

## Stap 6: Rapportage

Toon een korte samenvatting van wat er gebeurd is:

```
✓ Merged <CURRENT> into <DEFAULT>
  Merge commit: <abbrev SHA>
  Files changed: <N>, +<INS> -<DEL>
  Rebase preceded merge: yes/no
  Local source branch: deleted | kept (worktree at <path>)
```

`<abbrev SHA>` komt uit `git rev-parse --short HEAD`. `Files changed`, insertions en deletions uit `git diff --shortstat $DEFAULT~1...$DEFAULT`. De `Local source branch` regel reflecteert wat Stap 5 deed: `deleted` als `git branch -d` slaagde, `kept (worktree at <path>)` als de safety-check de delete oversloeg, of `kept (delete failed: <reden>)` als `-d` om een andere reden faalde.

Push gebeurt NIET in deze skill. Een push naar de remote is een aparte user-go (de user-CLAUDE.md push-regime documenteert dit). De gebruiker pusht zelf wanneer hij gevalideerd heeft dat de merge klopt.
