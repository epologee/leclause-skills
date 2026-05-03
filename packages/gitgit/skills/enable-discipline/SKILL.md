---
name: enable-discipline
user-invocable: true
description: >
  Use ONLY when the operator types `/gitgit:enable-discipline`. Do not auto-invoke.
  Re-enables the gitgit PreToolUse:Bash guards for the current Claude session
  by removing the sentinel file written by /gitgit:disable-discipline.
argument-hint: ""
---

# /gitgit:enable-discipline

Re-enable the gitgit PreToolUse:Bash guards for the current session.
Removes the sentinel that `/gitgit:disable-discipline` created. Has no
effect if the guards are already active.

## When to use

Only when the operator explicitly types this command. After running this
command, the guards apply again in full to all subsequent git commands in
the current session.

## Check status

Use `/gitgit:discipline-status` to see which sentinels are active and
what the current guard state is.

## Implementation

Perform the following steps:

1. Determine the current session_id via the same logic as `/gitgit:disable-discipline`:
   first `$CLAUDE_SESSION_ID`, then the most recent JSONL file under
   `~/.claude/projects/`, then fall back to global.

2. Remove the session-specific sentinel if it exists:

   ```bash
   SENTINEL="$HOME/.claude/var/gitgit-disabled-$SESSION_ID"
   if [[ -f "$SENTINEL" ]]; then
     rm "$SENTINEL"
     echo "gitgit guards re-enabled for session $SESSION_ID"
   else
     echo "gitgit guards were already active for session $SESSION_ID"
   fi
   ```

3. Also check the global sentinel and remove it if the operator means
   that (i.e. when there was no session-specific sentinel but there was
   a global one):

   ```bash
   GLOBAL="$HOME/.claude/var/gitgit-disabled-global"
   if [[ -f "$GLOBAL" ]]; then
     rm "$GLOBAL"
     echo "global gitgit sentinel removed"
   fi
   ```

4. Confirm to the operator which sentinel(s) were removed and at which path.

Do not write further explanation or caveats afterwards. The operator
typed this command deliberately.
