---
name: research
user-invocable: false
description: >
  Internal sub-skill of the recursion plugin. Not user-invocable:
  dispatched only by the recursion orchestrator (via Skill tool) or by
  a scheduled trigger that calls this skill by name. Runs the deep
  research workflow that produces atomic improvement plans: spawns
  parallel Opus agents for friction analysis and external discovery,
  synthesizes findings across three rounds, and writes self-contained
  plan files in ~/.claude/recursion/plans/. Research machine only,
  never executes the plans it produces.
allowed-tools:
  - Bash(date *)
  - Bash(stat *)
  - Bash(ls *)
  - Bash(mkdir *)
  - Bash(rm *)
  - Bash(git -C ~/.claude *)
  - Edit(~/.claude/recursion/**)
  - Write(~/.claude/recursion/**)
  - Read(~/.claude/**)
  - Glob(~/.claude/**)
  - Grep(~/.claude/**)
  - WebSearch
  - WebFetch(*)
  - Agent
effort: high
---

# Research

Research machine behind the recursion improvement loop. Produces
ready-to-execute plans through three rounds of deep research (exploration,
depth, contrarian). Writes plans to `~/.claude/recursion/plans/`.
Does not execute the plans.

Not user-invocable. Always called from the `recursion` orchestrator
or a scheduled trigger.

## State contract

The `recursion` orchestrator and `research` skill share
`~/.claude/recursion/`. To prevent race conditions, each
state field has exactly one writer:

| File / field | Owner | Other skill may |
|--------------|-------|-----------------|
| `state.md` `schedule_id` | `recursion` | read |
| `state.md` `focus` | `recursion` | read |
| `state.md` `last_run` | `research` | read |
| `state.md` `total_runs` | `research` | read |
| `state.md` Knowledge Base | `research` | read |
| `state.md` Sources Crawled | `research` | read |
| `blocklist.md` | `recursion` (append on reject) | read |
| `plans/*.md` new files | `research` | read |
| `plans/*.md` `status` field | `recursion` (flip to rejected) | read |

The plan body (all fields except `status`) is immutable after creation.

## Input

All input comes from state. No arguments. On start the skill reads:

1. `last_run` timestamp from `state.md` (determines friction analysis scope)
2. `focus` theme from `state.md` (determines which theme agents spawn)
3. `blocklist.md` (determines which findings are skipped)
4. existing plan slugs in `plans/` (prevents duplicates)

## Output

- New plan files in `~/.claude/recursion/plans/` following
  `${CLAUDE_SKILL_DIR}/prompts/plan-template.md`
- Updated `last_run`, `total_runs` fields in `state.md`
- Updated Knowledge Base and Sources Crawled sections in `state.md`
- Console notification with count and titles of written plans

## Workflow

Four top-level steps; RESEARCH contains three investigation rounds separated
by syntheses.

```
PREPARE → RESEARCH (round 1 → interim synthesis → round 2 → round 3 → final synthesis) → PLAN → NOTIFY → STOP
```

### 1. PREPARE

1. Fetch the date: `date +%Y-%m-%d`
2. Read `state.md`. Note `last_run`, `total_runs`, and `focus`.
3. Read `blocklist.md` fully into context (passed as a filter to
   Track A and B).
4. Scan existing plans: `ls ~/.claude/recursion/plans/*.md` to
   collect slugs.
5. Update `last_run` only after a successful PLAN phase, not here. A
   failed run must not be recorded as successful.

### 2. RESEARCH

This is the core. Thorough, radical, no shortcuts. Spawn parallel
agents per research direction with model choice per round: Sonnet for
breadth work (Track A friction grep, Track B exploration, round 2
depth) and Opus for the contrarian rounds and the final synthesis.

#### Round 1: Parallel exploration (Track A + Track B)

**Track A: Friction Analysis** (one agent, parallel with Track B)

Spawn a Sonnet agent with the prompt from
`${CLAUDE_SKILL_DIR}/prompts/friction-analysis.md`.
Analyzes session JSONLs since `last_run` for friction patterns:
corrections, overclaimed confidence, compliance reflex, premature action,
goal abandonment, downgrade spirals, repeated instructions,
self-improvement audit. Transcript grep and pattern classification are
mechanical work; Sonnet is qualitatively equivalent here and
substantially cheaper.

**Track B: External Research** (5-10 parallel agents)

Read `${CLAUDE_SKILL_DIR}/prompts/explore.md` for the full
instructions and privacy rules.

Spawn agents with `model: "sonnet"`, each focused on one source or
angle. Each agent goes DEEP: read full threads, follow links,
analyze discussions. Do not scrape titles; understand arguments.
Sonnet is sufficient for scraping, summarizing, and argument extraction;
the final synthesis in the main loop weighs depth against the contrarian rounds.

Required agents:

| Agent | Task |
|-------|------|
| Skills ecosystem | awesome-agent-skills, agentskills.io, anthropics/skills |
| Community | Reddit, HN, DEV Community discussions |
| Blogs | Known authors (Hudson, Sundell, Majid, AvdLee, Fatbobman) |
| Claude Code updates | Changelog, new features, breaking changes |
| Competitors | Cursor, Windsurf, Copilot workflow comparison |

When `focus` is set in state.md: spawn the theme-specific agents from
`explore.md § Theme-Specific Sources` on top of the required agents.
When `focus` is empty: broad exploration without a theme filter.

#### Interim synthesis (synchronous, after round 1)

Read all agent reports. Identify:

1. Most interesting leads for deeper investigation
2. Cross-pollination opportunities (friction + external)
3. Contradictions that need to be resolved
4. Concrete follow-up questions for round 2

#### Round 2: Targeted depth agents (3-5 agents)

Each agent receives a specific follow-up question from the interim synthesis
plus relevant findings from round 1. Spawn with `model: "sonnet"`;
targeted depth on a formulated question is within Sonnet's sweet spot.

#### Round 3: Contrarian verification (2-3 agents)

The counterweight against confirmation bias. Spawn with `model: "opus"`;
contrarian work requires the capacity to resist the most likely
conclusion, and Sonnet 4.6 shows documented quality flux on exactly
that pattern (claude-code issue 46935).

- **Contrarian**: find evidence that conclusions are wrong
- **Verification**: are sources independent or an echo chamber?
- **Applicability**: does this fit our constraints and philosophy?

#### Final synthesis

Incorporate all three rounds into a definitive narrative. Per conclusion:

- **Robust**: 3+ independent sources, contrarian did not refute
- **Probable**: 2+ sources, contrarian nuanced
- **Fragile**: 1 source, relevant counterarguments

Write synthesis to state.md Knowledge Base.
Update Sources Crawled dates.

### 3. PLAN

Translate each concrete finding into an atomic plan file following
`${CLAUDE_SKILL_DIR}/prompts/plan-template.md` (single source of truth
for schema and quality requirements).

Per finding that survives the final synthesis:

1. Check blocklist (already loaded in PREPARE). Is it on there? Skip.
2. Check existing plan slugs. Does one already exist with the same intent?
   Update or skip.
3. Write new plan file to `~/.claude/recursion/plans/` with
   `status: proposed`.

Only now (after the last write) is the run truly complete. Update
`last_run` and `total_runs` in state.md.

### 4. NOTIFY

Report to the console which plans were written:

```
Research complete: N plans written.

[titles]

Plans: ~/.claude/recursion/plans/
Run: /auto-loop ~/.claude/recursion/plans/<file>
```

## Safety

Single source of truth for privacy and safety rules. Also applies to
the `recursion` orchestrator when it delegates via the Skill tool.

- Track B exploration and round 2 depth agents run on Sonnet.
  Round 3 contrarian and the final synthesis MUST run on Opus;
  prompt injection resistance and the ability to resist the most likely
  conclusion weigh most heavily there.
- No project names, company names, or personal names in search queries
  (see `prompts/explore.md § Privacy Rules`).
- Do not upload content to external services.
- Research DOES NOT modify code, skills, hooks, or settings outside
  `~/.claude/recursion/`. Only plan files and state fields from the
  ownership table above.
- Blocklist items are never proposed again.
