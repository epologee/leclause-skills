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

- **Work just done (a diff):** Codex reviews the actual change set as a peer.
- **A design just discussed (no code yet):** Codex reflects on the plan
  read-only, without touching the tree.
- **Back and forth:** continue the same Codex session to push a point, defend
  yours, or ask the peer to reconsider.

The exact `codex exec` invocations live in the skill.

Codex's findings come home through three honest fates: fix, skip on cost versus
value, or reject as hollow. The exchange and any remaining disagreement are
surfaced to you.

## Requirements

The `codex` CLI must be installed and logged in; reviews run against your own
Codex account and quota, so a large diff is a real billed call. The skill
preflights for the CLI and stops with a plain message when no peer is available.

## Installation

```bash
/plugin install intervision@leclause
```
