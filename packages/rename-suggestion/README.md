# rename-suggestion

Generate a descriptive session name based on conversation context and copy the rename command to the clipboard.

## Commands

### `/rename-suggestion`

Reads the conversation, picks a short descriptive name (kebab-case, intent-revealing), and copies the corresponding rename command to the clipboard so you can paste and run it.

Also called by other skills when they finish a logical block of work and want to suggest a clearer session label.

## Installation

```bash
/plugin install rename-suggestion@leclause
```
