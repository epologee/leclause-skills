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

4. **Kopieer het volledige `/rename <naam>` command naar het clipboard** via de `clipboard-copy` helper uit de `clipboard@leclause` plugin (macOS-only). Resolve de plugin eerst, source daarna `clipboard-paths.sh`; beide bronnen van falen (plugin niet geïnstalleerd; of wel geïnstalleerd maar de cache is oud) krijgen elk een duidelijke stderr-regel:
   ```bash
   IP=$(jq -r '.plugins["clipboard@leclause"][0].installPath // empty' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
   if [ -z "$IP" ]; then
     echo "rename-suggestion: clipboard@leclause is not installed; skipping clipboard step. Run: claude plugins install clipboard@leclause to enable." >&2
   elif . "$IP/bin/clipboard-paths.sh" && CLIPBOARD_COPY=$(resolve_clipboard_copy); then
     printf '/rename <naam>\n' | "$CLIPBOARD_COPY"
   fi
   ```

   De clipboard-stap wordt overgeslagen wanneer de resolver faalt; de ghost-text suggestie werkt nog steeds omdat de `/rename` regel ook in de output staat.

5. **Toon het rename command als allerlaatste regel:**
   ```
   /rename <naam>
   ```

6. **Geen andere output na het command.** De `/rename` regel moet de allerlaatste tekst zijn, zodat de ghost text engine het als suggestie oppikt.
