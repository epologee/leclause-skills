---
name: test-before-push
user-invocable: true
description: De canonieke procedure om wijzigingen in een plugin-marketplace lokaal uit te rollen zodat je er in een andere Claude-sessie mee kan werken zonder eerst naar GitHub te pushen. Triggers op /test-before-push, "test dit lokaal", "test deze branch", "installeer in een andere sessie", "check voor de push".
---

# Test before push

One way, always. No choices, no options, no "option 1 or option 2". When you want to test a marketplace plugin in a new Claude session before pushing, follow the procedure below exactly as described.

## When to use

- You have been working locally in a marketplace repo (`.claude-plugin/marketplace.json` present in root)
- You want the new version to be loadable in a new Claude session outside this repo
- Pushing is not yet on the table; this is the pre-push test

Do not use when the repo is not a marketplace. Do not use for user-level skills in `~/.claude/skills/` (those load directly anyway).

## Preconditions

Run these checks as one bash block and confirm every line before continuing:

```bash
[ -f .claude-plugin/marketplace.json ] \
  && jq -r '.name' .claude-plugin/marketplace.json \
  && git status --short
```

First line: marketplace.json must exist in the repo root. Second line: read the alias from marketplace.json (e.g. `leclause`, `stekker`); that alias is silently overwritten by step 1 below. Third line: working tree clean, or commits land in this install.

## The procedure (step 1, push form)

```bash
claude plugins marketplace add ./
```

This re-points the alias (from marketplace.json) to the current working copy. Then, for each plugin you changed in this session:

```bash
claude plugins update <plugin>@<alias>
```

`<alias>` is what marketplace.json has as `name`. `<plugin>` is the plugin directory in `packages/`. The update pulls from the local working copy, not from GitHub. Cache path: `~/.claude/plugins/cache/<alias>/<plugin>/<version>/`.

Confirm success with:

```bash
jq '.plugins["<plugin>@<alias>"][0].version' ~/.claude/plugins/installed_plugins.json
```

That version must match the `version` in `packages/<plugin>/.claude-plugin/plugin.json`.

## In a new Claude session

Open a new Claude Code session in any directory (does not need to be this repo). The plugin is globally available via the user-scope install. Type the slash command of the plugin (for example `/gurus:software` for the gurus plugin) and test the behavior.

The current session where you ran this already has the old version loaded in memory. You will only see an update after restarting this session. For the test, go to a fresh session.

## The revert (step 2, after testing)

When you are done testing and ready to actually push, set the alias back to the GitHub source:

```bash
OWNER_REPO=$(git remote get-url origin | sed -E 's#.*github.com[:/](.+)/(.+)(\.git)?$#\1/\2#; s#\.git$##')
claude plugins marketplace add "$OWNER_REPO"
claude plugins update <plugin>@<alias>
```

This pulls the alias back to GitHub and loads the installed plugin from there (once you have pushed and the marketplace.json on main is fresh).

## Why this procedure and not another

Other paths that look tempting but are avoided:

1. **`claude plugins marketplace remove <alias>`** before re-adding. That cascade-uninstalls every plugin under that alias (empirical: 18 plugins lost at once). See how-plugins-work SKILL.md "Gotcha 1".
2. **Manually copying the plugin cache.** Works technically but drift between `installed_plugins.json` and the cache is invisible and breaks subsequent updates.
3. **Pushing a temporary branch.** That is exactly what we want to avoid until the test is done.

The `marketplace add ./` approach is a silent alias-overwrite and requires no remove, so no cascade. That is the only reason this procedure exists: it does it without losing plugins.

## Blockers and how to handle them

**`block-bad-paths` on absolute paths.** Work with `./` or `.` from the repo root, not with an absolute `/Users/.../` path. The user-level hook `block-bad-paths.sh` rejects absolute home paths. `./` is mapped internally by `claude plugins marketplace add` to an absolute path and stored, so you never need to type an absolute string yourself.

**`version` field in plugin.json does not match.** The leclause pre-commit hook bumps automatically on commit. If you have not committed since an edit, the version is one commit behind what the cache receives. Commit first, update after.

## Contract

This skill has no confirmation step. No "option 1 or option 2", no "agreed?". The only question that may come before the procedure is the preconditions check. Once that is green, the procedure is executed.
