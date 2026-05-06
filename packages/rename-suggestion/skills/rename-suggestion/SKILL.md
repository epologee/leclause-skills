---
name: rename-suggestion
user-invocable: true
description: Suggest a descriptive session name based on conversation context. Use when the user wants to rename the current session or when prompted by other skills. macOS-only clipboard copy.
args: ""
effort: low
allowed-tools:
  - Bash(jq *)
  - Bash(*clipboard-copy*)
---

<post-update-broadcast>
BEFORE doing the actual work below, run this one-time check:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast"
```

If the command produces output, the rename-suggestion plugin was updated since
the last time you saw the broadcast on this machine. Show the output
verbatim in a markdown block, prefixed with one short sentence
("rename-suggestion was updated; here is what changed."). Then continue with
the rest of this skill.

If the command produces no output, say nothing about updates and proceed.

The helper writes the sentinel only when stdout was non-empty, so a silent
run does not mark the version as seen. `/leclause:whats-new rename-suggestion`
re-shows the section on demand without touching the sentinel.
</post-update-broadcast>

# Session Rename Suggestion

Generate a short, descriptive session name based on the conversation context.

## Instructions

1. **Analyze the conversation** and determine the core topic:
   - What was done or discussed?
   - Focus on WHAT, not HOW
   - Be specific enough to distinguish this session from others

2. **Generate a concise name** (3-6 words):
   - Language follows the conversation context (Dutch conversation -> Dutch name, English code context -> English name)
   - No verbs like "implement" or "fix" at the start
   - Examples: `Thread tracking with emoji color codes`, `Unify search and payload commands`, `Session rename skill`

3. **Validation:** if the conversation has no identifiable core topic (session too short, too generic, or exclusively about topics that are not distinguishing such as "configuring Claude"), do not produce a made-up name. In that case use the placeholder `/rename <descriptive-name>` in step 4 and report in one sentence what information is missing to generate an appropriate name.

4. **Copy the full `/rename <name>` command to the clipboard** via the `clipboard-copy` helper from the `clipboard@leclause` plugin (macOS-only). Resolve the plugin first, then source `clipboard-paths.sh`; both failure modes (plugin not installed; or installed but the cache is stale) each get a clear stderr line:
   ```bash
   IP=$(jq -r '.plugins["clipboard@leclause"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
   if [ -z "$IP" ]; then
     echo "rename-suggestion: clipboard@leclause is not installed; skipping clipboard step. Run: claude plugins install clipboard@leclause to enable." >&2
   elif . "$IP/bin/clipboard-paths.sh" && CLIPBOARD_COPY=$(resolve_clipboard_copy); then
     printf '/rename <name>\n' | "$CLIPBOARD_COPY"
   fi
   ```

   The clipboard step is skipped when the resolver fails; the ghost-text suggestion still works because the `/rename` line also appears in the output.

5. **Show the rename command as the very last line:**
   ```
   /rename <name>
   ```

6. **No other output after the command.** The `/rename` line must be the very last text, so the ghost text engine picks it up as a suggestion.
