---
name: disable-discipline
user-invocable: true
description: >
  Use ONLY when the operator types `/gitgit:disable-discipline`. Do not auto-invoke
  even when commits are blocked by gitgit guards. Disables the gitgit
  PreToolUse:Bash guards for the current Claude session by writing a
  sentinel file to ~/.claude/var/. Other sessions are not affected.
argument-hint: ""
---

# /gitgit:disable-discipline

Schakel de gitgit PreToolUse:Bash guards uit voor de huidige sessie. Alle
guards (commit-format, commit-subject, commit-body, commit-trailers,
git-dash-c, push-wip-gate) worden gesloopt totdat de operator `/gitgit:enable-discipline`
runt. Andere sessies zijn niet beinvloed; de sentinel is sessie-specifiek.

## Wanneer te gebruiken

Alleen wanneer de operator dit commando expliciet typt. Gebruik dit nooit
automatisch om langs een geblokkeerde commit te komen. De guards bestaan om
een reden; het omzeilen ervan is de keuze van de operator, niet van Claude.

Typisch gebruik: een sessie die bewust buiten het normale commit-schema werkt
(bijv. een reeks triviale fixup-commits, een rebasing-sessie, of een
experimentele branch waar de discipline tijdelijk niet geldt).

## Herstel

Zet de guards terug met `/gitgit:enable-discipline`. Controleer de status met
`/gitgit:discipline-status`.

## Implementatie

Voer de volgende stappen uit:

1. Bepaal de huidige session_id. Lees `$CLAUDE_SESSION_ID` uit de omgeving
   als die beschikbaar is. Als alternatief: haal de session_id op via het
   transcript-pad dat in de hook-context beschikbaar is, of deriveer hem uit
   het meest recente JSONL-bestand onder `~/.claude/projects/`. Als geen van
   beide werkt, val terug op de globale sentinel (zie hieronder).

2. Als session_id beschikbaar is:

   ```bash
   mkdir -p "$HOME/.claude/var"
   touch "$HOME/.claude/var/gitgit-disabled-$SESSION_ID"
   echo "gitgit guards disabled for session $SESSION_ID"
   echo "Re-enable with /gitgit:enable-discipline"
   ```

3. Als session_id NIET beschikbaar is (fallback naar globale sentinel):

   ```bash
   mkdir -p "$HOME/.claude/var"
   touch "$HOME/.claude/var/gitgit-disabled-global"
   echo "gitgit guards disabled globally (session_id not available)"
   echo "WARNING: this sentinel disables guards for ALL sessions until removed."
   echo "Re-enable with /gitgit:enable-discipline"
   ```

4. Bevestig aan de operator welke sentinel is aangemaakt en welk pad.

Schrijf geen uitleg of caveats daarna. De operator heeft dit commando bewust
getypt.
