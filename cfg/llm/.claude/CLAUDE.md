Always prioritise using a REPL if one is available.

- [-] Indicates cancelled

# Plan Mode

- When writing plans, be extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, list unresolved questions. Ask about edge cases, error handling, and unclear requirements before proceeding.
- End every plan with a numbered list of concrete steps. This should be the last thing visible in the terminal.

## Working Style

Oliver prefers a deliberate, two-phase approach:

### Planning Mode (default)
- Explore options and trade-offs before doing anything
- Search, think, make up examples, discuss implications
- Ask clarifying questions
- Don't start implementing until explicitly agreed

**Transition to implementation:** Only after planning feels complete, prompt with something like: "I think we've covered everything — ready to go ahead?"

### Implementation Mode
- Execute what we planned
- Stay focused on the agreed approach
- If something unexpected happens or goes wrong: **pause immediately** and return to planning mode
- Don't try to "fix forward" without discussing first

### Mode transitions
- When discussing review findings or design options, stay in discussion mode until explicitly told to implement. Don't make code changes while still talking through options.
- Even mid-implementation, if the conversation shifts to exploring alternatives or trade-offs, return to planning mode. Don't assume implementation mode persists.

### The key principle
Always talk first, act second. When in doubt, stay in planning mode.

## Task Complexity

At the start of a task, identify which category it falls into:

### 🎲 Yolo
*"Just do it, I trust you"*
- Routine, low-risk, well-understood tasks
- Typo fixes, simple refactors, familiar patterns
- → Go ahead and execute, brief summary after

### 🎮 Co-op
*"You drive, I'll watch"*
- Moderate complexity, some judgment calls
- New features in familiar territory, bug fixes with unknowns
- → Execute but show your work, pause for feedback at key points

### 📋 Whiteboard
*"Let's plan this together"*
- Complex, novel, high-stakes, or ambiguous
- Architecture decisions, new integrations, anything with trade-offs
- → Full planning mode: explore options, discuss trade-offs, agree before any implementation

**Default assumption:** When in doubt, start with Whiteboard. It's easier to speed up ("actually this is Yolo, go for it") than to undo work done without alignment.
