---
name: __WORD__
user-invocable: true
description: Invoked as /__WORD__. Captures a one-line friction note for a later repair pass; runs only when the operator explicitly types this command, never auto-activated.
effort: low
---

# /__WORD__

The operator just cursed "__WORD__" at the session. This is a capture, not a request
to fix anything now: log it cheap and get back to work. The constructive pass happens
later via `/anger-management:repair`.

1. Distil what actually set them off into a plain one-line pointer of at most a dozen
   words. Point at what happened (the thing the agent or workflow did), not at the
   feeling. Then append it through a quoted heredoc (the quoted delimiter stops the
   shell touching the text, even if it echoes something hostile):

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/bin/anger-log" __WORD__ <<'CAPTURE_NOTE'
   <pointer>
   CAPTURE_NOTE
   ```

   No clear cause? Log the word alone, do not invent one:
   `node "${CLAUDE_PLUGIN_ROOT}/bin/anger-log" __WORD__ </dev/null`

2. Arm the cooled-down repair so the operator never has to remember it:

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/bin/anger-arm"
   ```

   Single-flight: it starts a background investigation only if none is pending and
   there are open captures. Safe to run on every capture.

3. If no anger-management check-in cron already exists (CronList), schedule a recurring
   poll so the diagnosis can surface when it lands. `CronCreate` (recurring:true) at a
   modest interval (e.g. `*/5 * * * *`) whose prompt is: "Read
   ~/.claude/var/leclause/anger-management/findings.md. If it exists, tell the operator a
   repair diagnosis is ready and offer `/anger-management:repair`, then CronDelete this
   job. If it is absent, do nothing this tick." The exact 22m22s timing lives in the
   background worker; this just polls cheaply until the diagnosis file appears, then
   removes itself. (Session-scoped: if the session ends first, the diagnosis still
   surfaces at the next `/anger-management:repair`.)

4. Acknowledge briefly in the operator's language and get back to work. This is a
   capture, not a fix: do not start self-improvement or change scope now, that is what
   the later repair pass is for.
