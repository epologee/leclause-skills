# dont-do-that

Six guardrail hooks that push back on common AI reflexes. Each hook either blocks a tool call or blocks the Stop event, forcing Claude to course-correct instead of barreling past the issue.

## Hooks

### PreToolUse (Bash)

**block-followup-without-issue**
Blocks `gh api` commands that contain "follow-up", "wordt opgepakt", "buiten scope", or similar deferral language in the body, unless the body starts with "Bewust uitgesteld:" (deliberately deferred). Prevents Claude from punting work to imaginary future PRs.

### PostToolUse (Edit, Write)

**block-inline-dashes**
Warns when em-dash or en-dash characters appear in `.md`, `.txt`, or `.mdx` files outside of code blocks or bullet points. Forces rewrites with commas, periods, or parentheses.

### Stop

**false-claims-guard**
Blocks Stop when the recent assistant text relativizes a test or error as already existing before the current change. Forces a fix or a factual defense.

**cache-excuse-guard**
Blocks Stop when the recent assistant text blames cache for a problem on localhost. On a dev server, cache is rarely the real cause. Forces investigation of the actual root cause.

**detect-compliance-reflex**
Blocks Stop when the last assistant message ends with a confirmation question ("wil je dat ik...?", "shall I...?") despite a clear user instruction. Claude can pass with a "Follow-up:" prefix for genuine new questions.

**nudge-after-tool-error**
Blocks Stop when the last significant event was a failed tool call. Forces analysis and retry instead of giving up. Maximum two nudges per session to prevent infinite loops.

## Installation

```bash
/plugin install dont-do-that@leclause
```

## Disabling individual hooks

All six hooks are enabled when the plugin is installed. To disable one without removing the plugin, override it in your user `settings.json`:

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
