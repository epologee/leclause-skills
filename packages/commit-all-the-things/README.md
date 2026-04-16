# commit-all-the-things

Commit every uncommitted change in the working tree, grouped into logical commits with descriptive messages. Useful when the working tree has drifted across several unrelated tasks and needs to be cleaned up in one pass.

## Commands

### `/commit-all-the-things`

Inspects `git status` and `git diff`, groups changes by intent (feature, fix, refactor, docs, config), and creates one commit per group. Each commit message follows the project's commit conventions (read from CLAUDE.md and recent `git log`).

Also triggers on Dutch phrases: "commit alles", "ruim de working tree op", "commit what's left".

## Behavior

- Reads project + user CLAUDE.md to pick up commit-message style, branch policy, and any opt-outs.
- Stages files individually rather than `git add -A`, so secrets and large binaries are not pulled in by accident.
- Never pushes. Push remains an explicit user action.

## Installation

```bash
/plugin install commit-all-the-things@leclause
```
