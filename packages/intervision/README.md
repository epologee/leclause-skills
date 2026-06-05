# intervision

Peer consultation for coding agents. Intervision is the practice of equals
reviewing each other's work, the opposite of supervision from above. This
plugin brings a second coding agent (Codex) in as that peer: you hand it the
work just done or just discussed, it looks with a different model and a fresh
read, and the two of you confer. The signal is the gap between two independent
agents, the spots where you and the peer disagree.

## Commands

### `/intervision:confer`

Hands the recent work to Codex through `codex exec` and confers about it. Three
shapes, picked by what just happened:

- **Work just done (a diff):** `codex exec review --uncommitted` (or `--base`,
  or `--commit`) so Codex reviews the actual change set as a peer.
- **A design just discussed (no code yet):** a read-only one-shot
  `codex exec -s read-only "<the plan and the open question>"`.
- **Back and forth:** `codex exec resume --last "<follow-up>"` to push on a
  point, defend yours, or ask the peer to reconsider.

Codex's findings come home through three honest fates: fix, skip on cost versus
value, or reject as hollow. The exchange and any remaining disagreement are
surfaced to you.

## Requirements

The `codex` CLI must be installed and logged in. The skill preflights for it
and stops with a plain message when no peer is available.

## Installation

```bash
/plugin install intervision@leclause
```
