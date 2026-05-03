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
  "gedrag"      # 1: subject = new behavior, not a git action
  "effect"      # 2: WHAT the system does, not the WHY trigger
  ""            #  3: owned by commit-format, no rotation slot
  "essentie"    # 4: body only 2-4 sentences of why
  "dubbelop"    # 5: file listings duplicate what the diff shows
  "proza"       # 6: prose, no bullet dumps or meta-narrative
  "atoom"       # 7: atomic commits, no drift
  "inferno"     # 8: never commit broken code with "fix in next"
  "solist"      # 9: no Co-Authored-By from AI tooling
  "incognito"   # 10: no Generated-with-Claude-Code footer
  "loep"        # 11: review staged diff before commit
  "bewijsstuk"  # 12: commit check is evidence, not gut feel
  "kralen"      # 13: preserve history, no squash merge
  "voorwaarts"  # 14: no amend, always a new commit
)
