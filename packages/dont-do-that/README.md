# dont-do-that

Nine guardrail hooks that push back on common AI reflexes. Each hook either blocks a tool call, blocks the Stop event, or surfaces additional context at the moment a mistake is likely, forcing Claude to course-correct instead of barreling past the issue.

## Hooks

### PreToolUse (Bash)

**block-followup-without-issue**
Blocks `gh api` commands that contain "follow-up", "wordt opgepakt", "buiten scope", or similar deferral language in the body, unless the body starts with "Bewust uitgesteld:" (deliberately deferred). Prevents Claude from punting work to imaginary future PRs.

**commit-message-rule-rotator**
Blocking. On every `git commit` Bash call, parses the subject from a `-m`, `-am`, `--message` or `--message=` flag, or from the first non-empty HEREDOC line, and selects one of fourteen commit-message rules. Rules 1 and 2 fire deterministically on activity-word starts (Fix, Improve, Update, Change, Refactor, Add, Extract, Move, Remove, Rename, Drop, Create, Clear) and trigger-as-reason phrasing (Address review/feedback/findings, Apply PR comments, Fix review comments). Rules 3 through 14 enter a rotation that advances only on a successful pass, so each thematic reminder gets one turn before the rotation wraps.

The hook exits 2 with a stderr explanation naming the selected rule and the required ack token `# ack-rule<N>` (lowercase, case-sensitive) that must appear in a subsequent `git commit` command as a trailing bash comment to pass. HEREDOC bodies and quoted strings are stripped before ack detection, so an ack token buried inside the commit message itself does not count. For violation rules the ack alone is not a bypass: the subject must also no longer violate. Editor-mode commits (no `-m`, no `--message`, no HEREDOC subject) are denied with an instruction to pass the subject inline so rules 1 and 2 can be inspected. If multiple `# ack-rule<N>` tokens appear in one command, the first one wins.

Violation pending and rotation pending are tracked as independent state fields, so an intervening violation never erases a pending rotation rule. State is stored at `$HOME/.claude/var/commit-rule-state` (three lines: pending violation index, pending rotation index, rotation position) and written atomically via a temp-file rename. The path is overridable via the `CLAUDE_COMMIT_RULE_STATE_FILE` env var for tests.

### PostToolUse (Edit, Write)

**block-inline-dashes**
Warns when em-dash or en-dash characters appear in `.md`, `.txt`, or `.mdx` files outside of code blocks or bullet points. Forces rewrites with commas, periods, or parentheses.

### Stop

**false-claims-guard**
Blocks Stop when the recent assistant text relativizes a test or error as already existing before the current change. Forces a fix or a factual defense.

**cache-excuse-guard**
Blocks Stop when the recent assistant text blames cache for a problem on localhost. On a dev server, cache is rarely the real cause. Forces investigation of the actual root cause.

**compliance-reflex-guard**
Blocks Stop when the last assistant message ends with a confirmation question ("wil je dat ik...?", "shall I...?") despite a clear user instruction. Claude can pass with a 🧭 (compass) prefix for genuine new questions or pre-emptive forward-looking statements.

**premature-interruption-guard**
Blocks Stop when the last assistant message does NOT end with a question, as a stop-gap against Claude Code tool chains that occasionally truncate before a chain-of-thought is complete. Claude can pass by ending the message with 🏁 (finish flag) when work is genuinely done. Mutually exclusive with compliance-reflex-guard by condition: that hook handles the "ends with ?" case, this one handles everything else.

**verification-delegation-guard**
Blocks Stop when the assistant delegates verification to the user ("zou moeten werken", "check of het werkt", "refresh de pagina") instead of verifying itself. Claude can pass by prefixing the conclusion with "Geverifieerd:" after actually running verification (screenshot, curl, test, grep). Filters meta-references (backtick-quoted strings, table cells) to reduce false positives when discussing the hook itself.

**nudge-after-tool-error**
Blocks Stop when the last significant event was a failed tool call. Forces analysis and retry instead of giving up. Maximum two nudges per session to prevent infinite loops.

## Installation

```bash
/plugin install dont-do-that@leclause
```

## Disabling individual hooks

All nine hooks are enabled when the plugin is installed. To disable one without removing the plugin, override it in your user `settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "" }
        ]
      }
    ]
  }
}
```

Or uninstall the plugin entirely if you want none of them:

```bash
/plugin uninstall dont-do-that@leclause
```

## Known quirk

These hooks scan assistant transcripts for trigger phrases. Documenting or discussing the hooks themselves can trigger them (meta false positives). If you are editing the scripts or writing docs about them, expect occasional Stop blocks.

## Language

All hooks match both Dutch and English trigger phrases.
