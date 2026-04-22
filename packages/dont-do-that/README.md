# dont-do-that

Nine guardrail hooks that push back on common AI reflexes. Each hook either blocks a tool call, blocks the Stop event, or surfaces additional context at the moment a mistake is likely, forcing Claude to course-correct instead of barreling past the issue.

## Architecture

One dispatcher, `hooks/dispatch.sh`, is registered against PreToolUse (Bash matcher), PostToolUse (Edit|Write|Bash matcher), and Stop. The dispatcher reads stdin once, extracts `hook_event_name`, and routes to the matching guard set. Guards live under `hooks/guards/` as sourced functions, shared helpers under `hooks/lib/common.sh`. No external script runs per guard.

Every user-visible hook message begins with the mnemonic prefix `[dont-do-that/<code>] `. The code is a stable short identifier that maps to the guard listed below. The message itself is a single actionable line. When you want the full rule behind a code, read this file or `hooks/guards/<code>.sh`.

## Codes and guards

### PreToolUse (Bash)

**`followup`** in `hooks/guards/followup.sh`
Denies `gh api` commands whose body contains deferral language ("follow-up", "wordt opgepakt", "buiten scope", "in een volgende pr", and similar) unless the body starts with `Bewust uitgesteld:`. Pass condition: prefix the body with `Bewust uitgesteld:` to claim an explicit deferral, or rewrite the body without deferral language.

**`commit-rule`** in `hooks/guards/commit-rule.sh`
On every `git commit` Bash call, parses the subject from `-m`, `-am`, `--message`, `--message=`, or the first non-empty HEREDOC line, and selects one of fourteen commit-message rules. Rules 1 and 2 fire on activity-word starts (Fix, Improve, Update, Change, Refactor, Add, Extract, Move, Remove, Rename, Drop, Create, Clear) and trigger-as-reason phrasing (Address review/feedback/findings/pride, Apply PR comments). Rules 3 through 14 are served in rotation; the rotation advances only on a passing ack. Pass condition: rewrite the subject if it violated, and add `# ack-rule<N>` as a trailing bash comment to confirm you read the rule. The full fourteen-rule text lives in `_DD_RULES` inside `hooks/guards/commit-rule.sh`.

HEREDOC bodies and quoted strings are stripped before ack detection so an ack token buried inside the commit message itself does not count. Editor-mode commits (no inline subject) are denied with an instruction to pass the subject via `-m` so rules 1 and 2 can be checked. State lives at `$HOME/.claude/var/commit-rule-state`, three lines (pending violation index, pending rotation index, rotation position), written atomically. Path overridable via `CLAUDE_COMMIT_RULE_STATE_FILE` for tests.

### PostToolUse (Edit, Write, Bash)

**`dash`** in `hooks/guards/dash.sh`
Surfaces additional context when em-dash (U+2014) or en-dash (U+2013) appears in `.md`, `.txt`, or `.mdx` files outside of fenced code blocks, in any persisted file content, or in a Bash command (clipboard, pipes). Chat is not checked. Does not block, only surfaces a rewrite instruction.

### Stop

**`pre-existing`** (false-claims) , `hooks/guards/false-claims.sh`
Blocks Stop when the recent assistant text relativizes a test or error as already existing before the current change. Also runs when `stop_hook_active` is true (keeps its own per-session line tracker). Pass condition: fix the failure, or formulate it as parallel work in the same directory when there is concrete evidence of a parallel session.

**`cache`** in `hooks/guards/cache.sh`
Blocks Stop when the recent assistant text blames cache for a problem on localhost. On a dev server, cache is rarely the real cause. Pass condition: investigate and name the actual root cause.

**`compliance`** in `hooks/guards/compliance.sh`
Blocks Stop when the last assistant message ends with a confirmation question ("Wil je dat ik...?", "Shall I...?", "Moet ik...?") despite a clear user instruction. Pass condition: continue the work and stop asking, or prefix the question with 🧭 for a genuine new direction.

**`premature`** in `hooks/guards/premature.sh`
Blocks Stop when the last assistant message does not end with a question AND does not end with 🏁 (finish) or 🚦 (waiting on external go) plus a substantive sentence (≥40 non-space non-emoji chars with a sentence terminator). Catches Claude Code tool chains that truncate before the chain-of-thought is complete, and bare emoji free passes. Mutually exclusive with `compliance` by condition. Pass condition: end with 🏁 + real sentence when work is done, or 🚦 + real sentence when waiting on an external go, or keep writing.

**`verify`** (verification-delegation) , `hooks/guards/verify.sh`
Blocks Stop when the assistant delegates verification to the user ("zou moeten werken", "check of het werkt", "refresh de pagina") instead of verifying itself. Meta-references (backticks, quoted strings, table cells) are stripped before matching. Pass condition: prefix the conclusion with `Geverifieerd:` after actually running verification (screenshot, curl, test, grep).

**`tool-error`** (nudge-after-tool-error) , `hooks/guards/tool-error.sh`
Blocks Stop when the last significant event in the transcript was a failed tool call. Also runs when `stop_hook_active` is true. Maximum two nudges per session (hard cap), with LINE_FILE tracking so we only fire on new errors. Pass condition: analyse the error and retry instead of giving up.

## Installation

```bash
/plugin install dont-do-that@leclause
```

## Disabling individual guards

The dispatcher always runs, but individual guards fire based on the message content. To silence one guard without removing the plugin, edit `hooks/dispatch.sh` in your install and comment out the matching `source` / `guard_<name>` line. To silence the plugin entirely, uninstall:

```bash
/plugin uninstall dont-do-that@leclause
```

## Known quirk

These hooks scan assistant transcripts for trigger phrases. Documenting or discussing the hooks themselves can trigger them (meta false positives). If you are editing the scripts or writing docs about them, expect occasional Stop blocks. The WIP escape hatch 🚧 in your assistant text skips Stop guards while you work on the hook system.

## Language

Trigger patterns match both Dutch and English phrasing. Messages are in Dutch.

## Tests

```bash
bash packages/dont-do-that/test/smoke-test.sh
```

The smoke test drives every trigger case through `hooks/dispatch.sh` with an explicit `hook_event_name`, matching the real runtime path. Exit 0 on all pass.
