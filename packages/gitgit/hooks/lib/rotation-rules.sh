#!/bin/bash
# Sourceable mnemonic-passwords for the commit-subject rotation reminders.
# Each ack must match the password tied to its rule number, e.g.
# `# ack-rule8:inferno`. The password is referential to the rule (vivid
# image you can hook the rule onto), so looking it up in the skill forces
# one exposure to the rule text per ack cycle. The skill at
# packages/gitgit/skills/commit-discipline/SKILL.md (section "Rotation
# reminders") is the canonical reference; this file is its enforcement
# mirror.

# Indexed 0-based: DD_RULE_PASSWORD[N-1] is the password for rule N.
# Rule 3 is owned by commit-format and not in the rotation; its slot stays
# empty so the index math lines up with the rule number.
DD_RULE_PASSWORD=(
  "gedrag"      # 1: subject = nieuw gedrag, geen git-actie
  "effect"      # 2: WAT het systeem doet, niet de WAAROM-trigger
  ""            #  3: owned by commit-format, no rotation slot
  "essentie"    # 4: body alleen 2-4 zinnen waarom
  "dubbelop"    # 5: file listings dubbelen wat de diff toont
  "proza"       # 6: prose, geen bullet dumps of meta-narrative
  "atoom"       # 7: atomic commits, geen drift
  "inferno"     # 8: nooit broken code committen met "fix in next"
  "solist"      # 9: geen Co-Authored-By van AI tooling
  "incognito"   # 10: geen Generated-with-Claude-Code footer
  "loep"        # 11: review staged diff voor commit
  "bewijsstuk"  # 12: commit-check is evidence, niet gut feel
  "kralen"      # 13: bewaar history, geen squash merge
  "voorwaarts"  # 14: geen amend, altijd nieuwe commit
)
