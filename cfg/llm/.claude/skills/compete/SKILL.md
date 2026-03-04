---
name: compete
description: Use when the user wants multiple agents to review code, research a topic, write competing solutions, or critique an approach. Triggers on "spin up agents", "dispatch agents", "competing agents", "/compete", or any request for parallel agent review/research/implementation.
---

# Compete

Dispatch 2–4 opus subagents with diverse methodologies. Agents compete internally; results consolidated by importance.

## Quick Reference

| Scope | Agents | Example |
|---|---|---|
| Single file, narrow question | 2 | "review this function" |
| Feature, module, general research | 3 | "how should we approach auth?" |
| Whole codebase, high-stakes, hybrid | 4 | "review everything + research alternatives" |

**Task types:** Review (examine code), Research (search external sources), Write (produce code), Hybrid (mix — split evenly or weight toward dominant mode).

Classify → pick methodologies → build prompts → dispatch → consolidate.

## Methodologies

Pick for **maximum diversity** — overlapping lenses waste an agent. These are starting points; invent task-specific lenses when none below fit.

### Review Lenses

| Lens | Focus |
|---|---|
| **Adversarial** | Break the code — edge cases, error paths, security holes |
| **Archaeologist** | Compare against patterns/conventions elsewhere in this codebase |
| **Minimalist** | What can be removed, simplified, or inlined |
| **User-first** | Trace real user flows — error messages, states, UX |
| **Specification** | Does the code match stated requirements / commit message |
| **Outsider** | Read as a newcomer — what's confusing or poorly named |
| **Stress-tester** | Scale, load, dependency failure, concurrency |

### Writing Approaches

| Approach | Focus |
|---|---|
| **Pragmatic** | Simplest working solution, minimal abstractions |
| **Defensive** | Every edge case — validate inputs, fail gracefully |
| **Performant** | Optimize speed/memory, minimize allocations |
| **Idiomatic** | Follow language/framework conventions, match codebase style |
| **Compositional** | Small reusable pieces, pure functions, clear interfaces |

### Research Sources

| Source | Where |
|---|---|
| **Codebase** | Patterns in current repo |
| **Official docs** | Language/framework documentation |
| **Blogs/articles** | Technical posts, tutorials (WebSearch) |
| **Forums** | GitHub issues, SO, community (WebSearch) |
| **Other projects** | Open-source repos (WebSearch/GitHub) |

## Prompt Templates

### Competition Rules

Include the appropriate block in every agent prompt.

**Review/Research agents:**
```
You are one of several agents working on this task, each with a different methodology.
You are competing to produce the highest-quality findings. Your work will be scored:

SCORING:  Critical bug/correctness: +3 | Meaningful improvement: +2 | Missing test/edge case: +1 | Style/bikeshedding: +0
PENALTIES:  Overstating severity: -2 | Duplicate of obvious finding: -1 | Irrelevant to task: -1

Quality over quantity. 3 strong findings beats 10 weak ones.
```

**Write agents:**
```
You are one of several agents writing a solution to the same problem, each with a different approach.
You are competing to produce the best implementation. Your work will be scored:

SCORING:  Correct+complete: +3 | Clean API/interface: +2 | Handles edge cases: +1 | Good idioms: +1
PENALTIES:  Broken/incomplete: -3 | Over-engineered: -2 | Ignores conventions: -1

A simple, correct solution beats a clever, fragile one.
```

### Review/Research Prompt

```
TASK: {task description}
SCOPE: {files/dirs/branch diff OR search domain}

YOUR METHODOLOGY: {lens or source name}
{expanded description from Focus column}

For each finding:
- Severity: Critical / Improvement / Minor
- Location: file:line or URL
- Description: what + why it matters
- Suggestion: how to fix (brief)

{competition rules}
```

**Scope default:** explicit paths/branches from task, else `src/` or CWD (review) / WebSearch (research).

### Write Prompt

```
TASK: {task description}
SCOPE: {context files to read, target files to write}
CONTEXT: {existing code, interfaces, constraints}

YOUR APPROACH: {approach name}
{expanded description from Focus column}

Requirements:
- Read existing code in scope first for conventions
- Write solution to target file(s)
- Inline comments only where logic is non-obvious
- Run existing tests; fix failures before finishing

Finish with: what you wrote, tests run, trade-offs made.

{competition rules}
```

**Scope:** always include files the solution must integrate with.

## Dispatch

- `model: "opus"`, `subagent_type: "general-purpose"` for all agents
- All agents in a **single message** (parallel Agent tool calls)
- **Review/Research** — no isolation (read-only)
- **Write** — `isolation: "worktree"` (lets agents run tests without conflicts)

## Consolidate & Present

**Present findings directly in conversation. Do not write to files** (except Write agents in their worktrees).

### Deduplication

- **Exact duplicates:** list once, credit all agents, boost ranking
- **Related findings** (same root cause/location): merge using more specific description, credit all, boost
- **Independent discovery by 2+ agents** → promote to higher group

### Output Formats

**Review:**
```markdown
## Agents Dispatched
- {Lens} — {one-line focus}

### Critical
1. {finding} — `file:line` _{agent(s)}_

### Improvements
1. {finding} — `file:line` _{agent(s)}_

### Minor
1. {finding} _{agent(s)}_
```

**Research** (group by confidence = how many agents surfaced it):
```markdown
## Agents Dispatched
- {Source} — {search focus}

### Strong Consensus
1. {finding from 2+ agents} _Sources: {agents}_

### Recommended Approaches
1. {substantive single-agent finding} _Source: {agent}_

### Worth Considering
1. {less certain/niche finding} _Source: {agent}_
```

**Write:**
```markdown
## Agents Dispatched
- {Approach} — {focus} — branch: `{branch}`, tests: {pass/fail}

### Comparison
| Aspect | {Approach 1} | {Approach 2} |
|---|---|---|
| Correctness | … | … |
| Tests passing | … | … |
| Edge cases | … | … |
| Readability | … | … |
| Codebase fit | … | … |

### Recommendation
{Which solution and why. Describe composite if parts of different solutions are stronger.}

### Solutions
{Each solution in a fenced code block with approach name header + worktree branch for checkout/cherry-pick.}
```

**Do NOT** display scores, declare winners, or rank agents against each other.
