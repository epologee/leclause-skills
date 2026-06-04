---
name: wtf
user-invocable: true
description: Invoked as /wtf. Logs a one-line friction paper-cut for later review; runs only when the operator explicitly types this command, never auto-activated.
effort: low
---

# /wtf

The operator vented "wtf". This is a friction paper-cut, not a request to fix
anything now. Capture it cheaply and move on; the constructive pass happens later
via `/anger-management`, where the full rationale lives.

1. Distil what grated into a plain one-line pointer of at most a dozen words, then
   append it through a quoted heredoc (always keep the delimiter quoted; that is
   what stops the shell interpreting the pointer):

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/bin/anger-log" wtf <<'VENT_NOTE'
   <pointer>
   VENT_NOTE
   ```

   No clear cause? Log the word alone, do not invent one:
   `node "${CLAUDE_PLUGIN_ROOT}/bin/anger-log" wtf </dev/null`

2. Let the command's `logged wtf: ...` line stand as the acknowledgement, plus at
   most one terse line. No "sorry", no analysis, no menu.
3. Do not start self-improvement and do not change scope. Resume the work.
