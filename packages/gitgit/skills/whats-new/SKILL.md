---
name: whats-new
user-invocable: true
description: Use ONLY when the operator types `/gitgit:whats-new`. Do not auto-invoke. Reprints the gitgit CHANGELOG section for the currently-installed plugin version, regardless of whether the post-update broadcast already fired on this machine.
---

# /gitgit:whats-new

Toon de CHANGELOG-sectie voor de huidige gitgit versie.

## Wat te doen

Roep de helper aan met `--force` zodat de sentinel wordt genegeerd:

```bash
node "${CLAUDE_PLUGIN_ROOT}/bin/check-broadcast" --force
```

Plaats de output letterlijk in een markdown blok in je antwoord. Geen
samenvatting, geen interpretatie; de CHANGELOG is canoniek.

Als de helper niets uitvoert, betekent dat: er is voor deze versie geen
CHANGELOG-entry. Meld dat in één regel en stop.

## Wat NIET te doen

- Geen edit op de CHANGELOG vanuit deze skill. De auteur onderhoudt 'm
  buiten Claude om.
- Geen bewerking van de sentinel. `--force` raakt 'm niet; alleen de
  niet-force broadcast (in `commit-all-the-things` en zusters) schrijft.
