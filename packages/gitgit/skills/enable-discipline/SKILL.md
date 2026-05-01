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

Heractiveer de gitgit PreToolUse:Bash guards voor de huidige sessie. Verwijdert
de sentinel die `/gitgit:disable-discipline` heeft aangemaakt. Heeft geen effect als de
guards al actief zijn.

## Wanneer te gebruiken

Alleen wanneer de operator dit commando expliciet typt. Na het runnen van dit
commando gelden de guards weer volledig voor alle volgende git-opdrachten in
de huidige sessie.

## Status controleren

Gebruik `/gitgit:discipline-status` om te zien welke sentinels actief zijn en wat de
huidige guard-toestand is.

## Implementatie

Voer de volgende stappen uit:

1. Bepaal de huidige session_id via dezelfde logica als `/gitgit:disable-discipline`:
   eerst `$CLAUDE_SESSION_ID`, dan het meest recente JSONL-bestand onder
   `~/.claude/projects/`, dan fallback naar global.

2. Verwijder de sessie-specifieke sentinel als die bestaat:

   ```bash
   SENTINEL="$HOME/.claude/var/gitgit-disabled-$SESSION_ID"
   if [[ -f "$SENTINEL" ]]; then
     rm "$SENTINEL"
     echo "gitgit guards re-enabled for session $SESSION_ID"
   else
     echo "gitgit guards were already active for session $SESSION_ID"
   fi
   ```

3. Controleer ook de globale sentinel en verwijder die als de operator dit
   bedoelt (d.w.z. als er geen sessie-specifieke sentinel was maar wel een
   globale):

   ```bash
   GLOBAL="$HOME/.claude/var/gitgit-disabled-global"
   if [[ -f "$GLOBAL" ]]; then
     rm "$GLOBAL"
     echo "global gitgit sentinel removed"
   fi
   ```

4. Bevestig aan de operator welke sentinel(s) zijn verwijderd en welk pad.

Schrijf geen uitleg of caveats daarna. De operator heeft dit commando bewust
getypt.
