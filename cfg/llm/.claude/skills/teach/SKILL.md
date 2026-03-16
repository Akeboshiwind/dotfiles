---
name: teach
description: Use when the user wants to learn a concept or technique. Triggers on "/teach", "teach me", "explain how to", or requests to understand a topic in depth with exercises. Usage - /teach <topic> <what the user wants to do>
---

# Teach

Research a topic, teach the relevant concepts, quiz the user, and optionally generate exercises in the current repo.

## Input

```
/teach <topic> <what the user is trying to do>
```

Examples:
- `/teach kotlin structured concurrency for parallel API calls`
- `/teach css grid layout for a dashboard`
- `/teach clojure transducers to process a large CSV pipeline`

## Flow

```
Parse input → Gauge level → Research → Teach → Quiz → Offer exercises
```

## 1. Parse Input

Extract two things from the user's message:

- **Topic**: the general domain (e.g., "kotlin", "css grid", "clojure transducers")
- **Task**: what they're trying to do or build (e.g., "parallel API calls", "dashboard layout", "CSV pipeline")

If either is unclear, ask before proceeding.

## 2. Gauge Level

Before researching, estimate the user's level from context clues:

- Their phrasing ("I'm new to X" vs "I know X but not Y")
- The codebase — does it already use the topic's language/framework? Check for existing patterns.
- User memories (if available)

Classify as one of:

| Level | Signals | Teaching style |
|---|---|---|
| **Newcomer** | "I'm learning X", no codebase evidence | Start from fundamentals, define terms |
| **Adjacent** | Knows the language but not this area | Bridge from what they know, skip basics |
| **Deepening** | Already uses it, wants specifics | Jump to nuance, edge cases, best practices |

State your assessment briefly: *"You seem to know Kotlin but are new to coroutines — I'll bridge from threads/callbacks."* Let the user correct you before continuing.

## 3. Research

Dispatch a **single** research agent (`model: "opus"`, `subagent_type: "general-purpose"`).

### Agent Prompt Template

```
You are a research agent preparing material for a teaching session.

TOPIC: {topic}
TASK: {what the user wants to do}
USER LEVEL: {newcomer/adjacent/deepening} — {brief context}

Research the concepts needed to accomplish the TASK. Be focused — only cover what's directly relevant.

DO:
- Search official documentation (WebSearch)
- Search for practical examples and common patterns (WebSearch)
- Check the current codebase for existing usage of this topic (Grep/Glob)
- Find common pitfalls and misconceptions for this specific use case
- Collect 2-3 small, illustrative code examples

DO NOT:
- Write a comprehensive tutorial on the entire topic
- Include history or background that doesn't help with the task
- Duplicate information across sections

Return your findings structured as:

### Key Concepts
{Ordered list of concepts needed, from foundational to task-specific. For each: name, one-line explanation, why it matters for the task.}

### Codebase Context
{Any existing patterns, conventions, or examples found in the current repo. "None found" if nothing relevant.}

### Code Examples
{2-3 small, runnable examples that build toward the task. Annotate key lines.}

### Pitfalls
{Common mistakes when doing this specific task. What goes wrong and why.}

### Mental Model
{One analogy or mental model that makes the concept click. Tailor to user level.}
```

## 4. Teach

Present the research findings directly to the user, structured as:

```markdown
## {Topic}: {Task}

> {One-sentence mental model / analogy}

### Concepts

{Walk through key concepts in order. For each:}
**{Concept name}** — {explanation tailored to user level}

{Code example if helpful, keep short}

### In This Codebase

{Existing patterns found, or "No existing usage found — you'll be introducing this."}

### Watch Out For

{Pitfalls as a bulleted list, each with a brief "why" and "instead, do..."}
```

Keep it concise. The user wants to learn enough to do the task, not read a textbook.

## 5. Quiz

Present **3-5 questions** all at once. Mix question types:

- **Conceptual**: "What happens if X?" / "Why does Y work this way?"
- **Applied**: "Given this code, what's the output?" / "What's wrong with this snippet?"
- **Task-specific**: "How would you apply X to do {the user's task}?"

Format:

```markdown
## Check Your Understanding

1. {Question}

2. {Question with code snippet}
   ```{lang}
   {code}
   ```

3. {Question}

---

Take your shot — I'll give feedback on each answer.
```

When the user answers, provide feedback on each: correct/incorrect, brief explanation, and point them back to the relevant concept if wrong.

## 6. Offer Exercises (Optional)

After the quiz, offer:

```
Want me to create some exercises in the repo? I'll set up test files where you write the implementations.
```

If accepted:

- **Detect the language and project structure** from the codebase
- **Place files idiomatically** — e.g., `src/test/kotlin/exercises/`, `test/exercises/`, etc. Use your judgment based on the project.
- **Create 2-4 exercises** that build in difficulty toward the user's task
- Each exercise: a test file with failing tests and clear docstrings describing what to implement
- Include a stub/skeleton file for the user to fill in
- The final exercise should be close to the user's actual task

Tell the user where the files are and how to run them.

## Notes

- Stay focused on the user's task. Breadth is the enemy of useful teaching.
- If the user asks follow-up questions during any phase, answer them before continuing.
- If the codebase reveals the user is more/less experienced than initially assessed, adjust.
