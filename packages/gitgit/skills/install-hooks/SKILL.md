---
name: install-hooks
user-invocable: true
description: >
  Install gitgit's four git-native hooks (commit-msg, prepare-commit-msg,
  post-commit, pre-push) into the current repo so commits and pushes done
  outside Claude Code (CLI, IDE, another tool) still get the body-schema
  validation and wip-gate enforcement. Run once per clone. Use --force to
  overwrite existing hooks.
argument-hint: "[--force] [--dry-run]"
---

# Install Hooks

Plaats de vier git-native hooks van gitgit in de huidige repo, zodat commits
en pushes die buiten Claude Code om gemaakt worden ook worden bewaakt.

De vier hooks:

| Hook | Doel |
|------|------|
| `commit-msg` | Valideert het commit-bericht tegen `validate-body.sh` (zelfde lib als de PreToolUse guard). |
| `prepare-commit-msg` | Pre-fills het editor-venster met een gestructureerd body-template op basis van de staged diff. |
| `post-commit` | Detecteert `--no-verify` gebruik en logt het naar `~/.claude/var/gitgit-no-verify.log`. |
| `pre-push` | Herdraaait de wip-gate op de push-range: commits met `Slice: wip` worden geblokkeerd. |

## Waarom

De PreToolUse:Bash guard (slice 4) dekt alleen Claude-aangedreven commits.
Commits die rechtstreeks via `git commit` op de shell of vanuit een IDE
worden gemaakt zien deze guard niet. Claude Code biedt geen native
`PreCommit` lifecycle event en zal dat ook niet krijgen
(https://github.com/anthropics/claude-code/issues/4834 closed not planned),
dus de per-repo git-native hooks zijn de enige manier om non-Claude commits
en pushes te dekken.

Alle hooks delen dezelfde `validate-body.sh` als de PreToolUse-guard, zodat
gedrag nooit divergeert.

## Wat de skill doet

1. Verifieert dat we in een git repo zitten (`git rev-parse --git-dir`).
2. Detecteert of `core.hooksPath` is gezet, en kiest de juiste doeldir
   (`.git/hooks/` of de waarde van `core.hooksPath`).
3. Vindt het plugin-install-pad via `~/.claude/plugins/installed_plugins.json`
   en bakt dat absolute pad in elke hook in (placeholder
   `__PLUGIN_INSTALL_PATH__` wordt vervangen). Re-run na een plugin-update
   ververst het pad.
4. Kopieert per hook (`commit-msg`, `prepare-commit-msg`, `post-commit`,
   `pre-push`) de bron uit de plugin naar de doeldir, zet de executable bit,
   en logt het resultaat.

## Defaults en flags

- Default: per hook, als de doelfile al bestaat met een afwijkende inhoud,
  weigert de skill te overschrijven en print de diff. Idempotent: een
  bestaande file met identieke inhoud is een silent no-op.
- `--force`: maakt voor elke conflicterende hook een backup
  (`<hook>.bak.<timestamp>`) en overschrijft daarna.
- `--dry-run`: toont wat er zou gebeuren zonder iets te schrijven.

## Hoe te gebruiken

```bash
# Standaard install in de huidige repo:
bash "$(jq -r '.plugins["gitgit@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)/skills/install-hooks/lib/install.sh"

# Of via de skill-invocatie:
/gitgit:install-hooks
/gitgit:install-hooks --dry-run
/gitgit:install-hooks --force
```

De skill draait `lib/install.sh` uit deze skill-directory. Het script
detecteert zelf het plugin-installatiepad via `installed_plugins.json` en
heeft verder geen argumenten nodig.

## Conflict-detectie en escape hatches

- Bestaande hook met andere inhoud zonder `--force`: skill print
  unified diff (`diff -u`), weigert te overschrijven, en exit 1.
- Bestaande hook met identieke inhoud: silent no-op (idempotent).
- `--no-verify` op `git commit` blijft een geldige escape voor de auteur;
  de geinstalleerde `post-commit` logt dat gebruik naar
  `~/.claude/var/gitgit-no-verify.log` zodat het achteraf auditeerbaar is.
- Het magic comment `# vsd-skip: <reason>` in de body skipt validatie
  en logt naar `~/.claude/var/gitgit-skips.log` (afgehandeld door
  `validate-body.sh`).

## Voorbeeld output

```
gitgit:install-hooks
  hooks dir   : .git/hooks (default)
  plugin path : ~/.claude/plugins/cache/epologee/gitgit/1.0.30
  installed   : commit-msg
  installed   : prepare-commit-msg
  installed   : post-commit
  installed   : pre-push
  skipped     : (none)
  backups     : (none)
done.
```

Met een conflict zonder `--force`:

```
gitgit:install-hooks
  hooks dir : .git/hooks
  WARN: .git/hooks/commit-msg already exists with different content.
  --- existing
  +++ new
  @@ -1,3 +1,5 @@
  ...
  Refusing to overwrite. Re-run with --force to backup-and-replace.
exit 1
```

## Post-update procedure

Na elke `claude plugins update gitgit@leclause` is het baked plugin-pad in de
geinstalleerde hooks verouderd. Draai in elke repo waar de hooks actief zijn:

```bash
/gitgit:install-hooks --force
```

Dit vervangt de bestaande hooks (met automatische backup) en bakt het nieuwe
pad in. Zonder deze stap zullen de hooks bij de volgende commit het oude
plugin-pad proberen te sourcen, wat kan mislukken als de cache-directory is
opgeruimd.
