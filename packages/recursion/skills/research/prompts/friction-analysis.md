# Recursion Friction Analysis

Instructions for the friction analysis agent. You analyze conversation sessions to
find patterns where user and Claude talk past each other, goals are not
reached, or Claude repeatedly needs to be corrected.

## Goal

Produce concrete proposals for CLAUDE.md adjustments or new skills
that structurally address recurring friction patterns.

## Data Sources

### Primary: session JSONLs (full conversations)

Location: `~/.claude/projects/<project-dir>/<session-id>.jsonl`

Format: line-delimited JSON. Each line has a `type` field:
- `type: "user"` and `type: "assistant"` contain conversation content
- Content is in `d["message"]["content"]` (string or list of content blocks)
- Content blocks: `{"type": "text", "text": "..."}` for text

**Scoping:** Analyze only sessions modified since the previous recursion run.
Check `last_run` in state.md and filter on file modification time.

**Sampling:** Sessions >500 lines: read first 150 and last 150 lines.
This captures both the initial setup and the conclusion (where friction often lives).

### Secondary: history.jsonl (user messages only)

Location: `~/.claude/history.jsonl`

Format: `{"display": "...", "timestamp": ..., "project": "...", "sessionId": "..."}`

Use for a quick scan of correction patterns across all projects.
Filter on timestamp since the previous run.

### Tertiary: git log

`git log --all --oneline` for revert patterns, fix-the-fix commits.

## Friction Patterns

### 1. Corrections (severity: medium-high)

User corrects Claude directly after a response.

**Signal words in user messages (Dutch, since the user types in Dutch):**
- "nee", "niet dat", "ik bedoelde", "dat klopt niet"
- "stop met", "dat zei ik toch al", "lees nog eens"
- Short corrections after long Claude output (e.g. "X moet Y zijn")
- Reformulation of the same instruction

**Analysis per correction found:**
- What did Claude say that needed to be corrected?
- Was this an interpretation error (intent misread)?
- Was this a knowledge error (fact incorrect)?
- Was this a convention violation (existing rule not followed)?
- Is there a CLAUDE.md rule that should have prevented this?

### 2. Overclaimed Confidence (severity: high)

Claude presents uncertain information as fact.

**Signals (Dutch user phrases):**
- User asks "weet je dat zeker?", "kun je dat onderbouwen?"
- User asks for verification of a claim
- Claude admits something "was een gok"
- Claude retracts an earlier assertion

**Analysis:** This is most dangerous when it ends up in external output
(GitHub issues, PR descriptions, documents). Always note whether the
overclaimed information landed in an external artifact.

### 3. Compliance Reflex (severity: low-medium)

Claude stops and asks permission for something that was already in scope.

**Signals (Dutch user phrases):**
- "Wil je dat ik...?" after an explicit instruction
- "Zal ik ook...?" for something the user already mentioned
- Summary between two tool calls instead of continuing
- User responds with "ja", "doe maar", "uiteraard"

**Analysis:** Check whether the CLAUDE.md "keep working" section already
covers this pattern. If yes: it is a compliance problem, not a rule problem.
If no: propose a rule.

### 4. Premature Action (severity: medium)

Claude starts implementing before the instruction is clear.

**Signals (Dutch user phrases):**
- User asks a question, Claude immediately makes changes
- User says "laat maar" or "revert" shortly after a change
- User reformulates the instruction after a first attempt

**Analysis:** Was the user brainstorming or giving an instruction?
Difference: question form ("willen we niet...?") vs. imperative form ("doe X").

### 5. Goal Abandonment (severity: high)

A conversation starts with goal X but ends without X being achieved.

**Signals:**
- First user message states a clear goal
- Last 10 messages are about something else
- No confirmation that the original goal was achieved
- Session ends on a tangential topic

**Analysis:** Was the goal explicitly abandoned (user chose a different direction) or
implicitly lost (drift without a conscious choice)?

### 6. Downgrade Spiral (severity: high)

Claude tries approach A, then B, then C, with decreasing quality.

**Signals:**
- Three or more tool calls with similar intent but different approach
- Revert-like patterns (write code, then undo it, then do it differently)
- User says "probeer X" after a failed attempt (reactive instead of proactive)

**Analysis:** Check whether the CLAUDE.md "iterative downgrading is forbidden" rule
already covers this pattern. If the rule exists but is not followed, it is a
compliance problem. If the rule does not cover what happened, propose a
tightening.

### 7. Repeated Instruction (severity: medium)

The same instruction recurs across multiple sessions.

**Detection via history.jsonl:** Look for semantically similar user messages
(not literally the same text, but the same intent) across multiple sessions.

**Analysis:** If the user repeatedly has to give the same instruction, there is
a missing CLAUDE.md rule, skill, or hook that would enforce it automatically.

### 8. Self-improvement Audit (severity: high, always run)

`/self-improvement` invocations are the highest-signal friction indicator:
the user is literally saying "this needs to change structurally." Analyze EVERY
`/self-improvement` in the analyzed sessions.

**Detection:** Search user messages for `/self-improvement` (literal string).

**Per invocation, analyze the full chain:**

1. **Trigger**: What was the friction moment that triggered the invocation?
   Read the 3-5 user messages before the invocation. What went wrong?
2. **Instruction**: What did the user ask self-improvement to do?
   Sometimes the instruction is in the same message, sometimes in the next one.
3. **Execution**: What did self-improvement actually do?
   Read the assistant messages after the invocation. Which files were
   changed? Which rules were added or adjusted?
4. **Effectiveness**: Did the change solve the original problem?
   - Check whether the same friction pattern recurs in later sessions
   - Check whether the added rule or skill is concrete enough to prevent the
     pattern (or too vague or broad)
   - Check whether the rule is in the right place (CLAUDE.md vs. skill vs. hook)
5. **Missed opportunities**: Should self-improvement have done more?
   - Was there a broader pattern that was not addressed?
   - Would a hook have enforced it better than a CLAUDE.md rule?
   - Should an existing skill have been sharpened?

**Output per invocation:**

```markdown
#### Self-improvement: [short description of trigger]
- **Trigger**: [what went wrong]
- **Requested action**: [what the user wanted]
- **Executed action**: [what actually changed]
- **Effectiveness**: succeeded / partial / failed
- **Reason**: [why it was or was not effective]
- **Proposal**: [follow-up action if the fix was incomplete]
```

**Concentration analysis:** `/self-improvement` typically comes in bursts:
3-12 invocations within 30-90 minutes, multiple times per day. That is
normal usage, not an alarm signal. The interesting question is not
frequency but *thematic repetition*: do the same types of corrections
(e.g. language choice, naming, tool usage) recur across multiple clusters?
That indicates a self-improvement that did not structurally solve the
underlying problem. Analyze per theme whether earlier fixes were effective,
not per time interval.

## Output Format

```markdown
## Friction Analysis [date]

### Sessions Analyzed
- N sessions, M projects, period X-Y

### Findings

#### High Severity
1. **[pattern type]** session: description
   - User message: "quote"
   - Claude error: what went wrong
   - Root cause: why
   - Proposal: CLAUDE.md rule / skill / hook
   - Impact: how often this pattern occurs

#### Medium Severity
...

#### Low Severity
...

### Self-improvement Audit
Per `/self-improvement` invocation: trigger, action, effectiveness, proposal.
On concentration (3+ in a week): name the overarching pattern.

### Proposed Actions
Per proposal:
- Type: CLAUDE.md adjustment / new skill / hook / existing skill change
- Description: concrete change
- Expected impact: which friction pattern this addresses
- Risk: chance of false positives or unwanted side effects
```

## Privacy

- Quote user messages only with enough context for the analysis
- No project names, company names, or personal names in output
  that goes outside (recap, notifications)
- Session IDs are internal, do not share externally
- Do not copy code fragments from sessions into proposals
