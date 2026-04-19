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

# Session Rename Suggestion

Genereer een korte, beschrijvende sessienaam op basis van de conversatiecontext.

## Instructies

1. **Analyseer de conversatie** en bepaal het kernonderwerp:
   - Wat is er gedaan of besproken?
   - Focus op WAT, niet HOE
   - Wees specifiek genoeg om deze sessie te onderscheiden van andere

2. **Genereer een beknopte naam** (3-6 woorden):
   - Taal volgt de context van het gesprek (Nederlands gesprek -> Nederlandse naam, Engelse code context -> Engelse naam)
   - Geen werkwoorden als "implementeer" of "fix" aan het begin
   - Voorbeelden: `Thread tracking with emoji color codes`, `Unify search and payload commands`, `Session rename skill`

3. **Validatie:** als de conversatie geen identificeerbaar kernonderwerp heeft (sessie te kort, te generiek, of uitsluitend over onderwerpen die niet onderscheidend zijn zoals "Claude configureren"), produceer geen verzonnen naam. Gebruik dan in stap 4 de placeholder `/rename <beschrijvende-naam>` en meld in één zin welke informatie ontbreekt om een passende naam te genereren.

4. **Kopieer het volledige `/rename <naam>` command naar het clipboard** via de `clipboard-copy` helper uit de `clipboard@leclause` plugin (macOS-only). Source `clipboard-paths.sh` om het pad te resolven en een nette foutmelding te krijgen als de plugin ontbreekt of de cache achterloopt:
   ```bash
   . "$(jq -r '.plugins["clipboard@leclause"][0].installPath' ~/.claude/plugins/installed_plugins.json)/bin/clipboard-paths.sh"
   CLIPBOARD_COPY=$(resolve_clipboard_copy) || { echo "(clipboard step skipped; ghost-text suggestion still works below)" >&2; CLIPBOARD_COPY=""; }
   if [ -n "$CLIPBOARD_COPY" ]; then
     printf '/rename <naam>\n' | "$CLIPBOARD_COPY"
   fi
   ```

   Op systemen zonder de `clipboard` plugin of op non-macOS is `CLIPBOARD_COPY` leeg en wordt de clipboard-stap overgeslagen; de ghost-text suggestie werkt nog steeds omdat de `/rename` regel ook in de output staat.

5. **Toon het rename command als allerlaatste regel:**
   ```
   /rename <naam>
   ```

6. **Geen andere output na het command.** De `/rename` regel moet de allerlaatste tekst zijn, zodat de ghost text engine het als suggestie oppikt.
