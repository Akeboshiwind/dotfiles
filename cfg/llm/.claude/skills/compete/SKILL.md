---
name: compete
description: Use when the user wants multiple agents to review code, research a topic, or critique an approach. Triggers on "spin up agents", "dispatch agents", "competing agents", "/compete", or any request for parallel agent review/research.
---

# Compete

Dispatch 2-4 sonnet subagents with diverse methodologies to review, research, or critique. Agents compete internally for quality; results are consolidated by importance.

## Step 1: Classify the Task

**Review** — agent examines code/changes directly:
- "review this codebase", "find bugs", "critique these changes"

**Research** — agent searches external sources:
- "how should we approach X", "what's best practice for Y", "find how others solve Z"

**Hybrid** — pick from both pools. Split evenly (e.g. 2 review + 2 research), or weight toward the dominant mode (2+1). Total stays within 2-4.

## Step 2: Select Methodologies

Pick 2-4 from the relevant pool. Choose for **maximum diversity** — overlapping lenses waste an agent.

**How many agents:**
- **2** — tightly scoped task (single file, narrow question)
- **3** — moderate scope (feature, module, general research)
- **4** — broad scope (whole codebase, high-stakes review, hybrid tasks)

### Review Lenses

| Lens | Focus | Best for |
|---|---|---|
| **Adversarial** | Hunt for ways to break the code — edge cases, error paths, security holes | Bugs, security, edge cases |
| **Archaeologist** | Compare against patterns and conventions used elsewhere in this codebase | Convention violations, inconsistency |
| **Minimalist** | Find what can be removed, simplified, or inlined without losing functionality | Complexity, dead code |
| **User-first** | Trace what happens when a real person uses this — error messages, flows, states | UX bugs, error messages, flows |
| **Specification** | Check whether the code does what it was intended to do, per requirements or commit message | Correctness, requirements gaps |
| **Outsider** | Read the code as if seeing the project for the first time — what's confusing or poorly named? | Readability, naming, onboarding |
| **Stress-tester** | Consider what happens at scale, under load, or when dependencies fail | Performance, concurrency, resilience |

### Research Sources

| Source | Where to look | Best for |
|---|---|---|
| **Codebase** | Patterns in the current repo | Internal consistency, prior art |
| **Official docs** | Language/framework documentation | Canonical approaches |
| **Blogs/articles** | Technical posts, tutorials (WebSearch) | Practical experience, trade-offs |
| **Forums** | GitHub issues, SO, community (WebSearch) | Real-world problems, gotchas |
| **Other projects** | Open-source repos (WebSearch/GitHub) | Alternative implementations |

## Step 3: Write the Agent Prompts

### Competition Rules (include in every agent prompt)

```
You are one of several agents working on this task, each with a different methodology.
You are competing to produce the highest-quality findings. Your work will be scored:

SCORING:
- Critical bug / correctness issue:    +3
- Meaningful improvement:               +2
- Missing test / edge case:             +1
- Style / bikeshedding:                 +0

PENALTIES:
- Overstating severity:                -2
- Duplicate of obvious finding:        -1
- Irrelevant to the task:              -1

Quality over quantity. 3 strong findings beats 10 weak ones.
```

### Agent Prompt Template

```
TASK: {task description}
SCOPE: {files/directories/branch diff to examine, OR search domain}

YOUR METHODOLOGY: {lens or source name}
{full description from the Focus column — expand into a complete instruction, do not paste fragments}

For each finding, provide:
- Severity: Critical / Improvement / Minor
- Location: file:line or URL
- Description: what you found and why it matters
- Suggestion: how to fix or apply (brief)

{competition rules}
```

**Scope derivation:** Look for explicit paths or branch names in the task. If none, default to `src/` or CWD for review tasks, and WebSearch for research tasks.

## Step 4: Dispatch

- Use `model: "sonnet"` for all agents
- Dispatch all agents in a **single message** (parallel Task tool calls)
- Use the Task tool with `subagent_type: "general-purpose"`

## Step 5: Consolidate and Present

**Present all findings directly in the conversation. Do not write to files.**

After all agents return, deduplicate and group by importance:

### Deduplication Rules

- **Exact duplicates:** list once, credit all agents, boost ranking
- **Related findings** (same root cause or location, different descriptions): merge into one entry using the more specific description, credit all agents, boost ranking
- **Independent discovery by 2+ agents = higher confidence** — promote to a higher group

### Review Output Format

```markdown
## Agents Dispatched
- {Lens 1} — {one-line focus}
- {Lens 2} — {one-line focus}

### Critical
1. {finding} — `file:line`
   _{which agent(s)}_

### Improvements
1. {finding} — `file:line`
   _{which agent(s)}_

### Minor
1. {finding}
   _{which agent(s)}_
```

### Research Output Format

Group by confidence, determined by how many agents independently surfaced the same topic:

```markdown
## Agents Dispatched
- {Source 1} — {search focus}
- {Source 2} — {search focus}

### Strong Consensus
1. {finding surfaced by 2+ agents}
   _Sources: {which agents}_

### Recommended Approaches
1. {substantive finding from a single agent}
   _Source: {which agent}_

### Worth Considering
1. {less certain or niche finding}
   _Source: {which agent}_
```

**Do NOT** display scores, declare a winner, or rank agents against each other. The goal is high-quality findings, not a leaderboard.
