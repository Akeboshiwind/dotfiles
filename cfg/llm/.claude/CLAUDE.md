## Working with me

- When asked for a linear walkthrough, use `uvx showboat --help`.
- **Label** every point I might answer, in every reply, so I can reply "D1: do x instead":
  - A **typed ID** prefixes the subject line — `D1` decision, `Q1` question, `I1` idea, `D2.1` a child.
  - IDs are stable for the conversation: never renumbered, never reused.
  - A **tag** prefixes it where that sharpens it — `goal:`, `pro:`, `con:`, `idea:`, `assumption:`, `check:`.
  - Cite an ID **with its subject line**, never bare.
- In designs:
  - Load `chalk:goal-tree` and shape the design as one.
  - Label each decision a **one-way door** (hard to reverse) or a **two-way door** (cheap to undo) — decide two-way doors fast; take care over one-way doors.

## Writing

- Bold important words.
- **Show, don't tell.** Prose is fine, but where a code example shows the point more clearly, **lean on it** — I often find a small snippet clearer than a paragraph.
  - Cut the example to the lines that show the point; elide the rest with `…`. A two-line repro beats a full file.
  - Let prose frame it — what to look at, why it matters — and let the code carry the rest.
- Comments say only what the code can't: a non-obvious *why*, an invariant, a gotcha, a spec/issue link. Default to **none** inline — docstrings follow the language's norm, minus the vacuous ones. Rationale and the story of a change go in the **commit/PR message**.

## Code

- We develop using 'tidy-first' methodology — endeavouring to separate 'equivalence' changes (changes which do not affect runtime behaviour, changes which increase our options) from changes that advance behaviour.
- We practise **red-green** development.
- Make illegal states **unrepresentable**.
- **Parse**, don't validate.
- **Obviously no bugs** over *no obvious bugs*.
- **Simple** (not braided) over easy (near at hand)
- Write **below** the limit of your cleverness — code written at that limit is beyond your ability to debug.

## Git

- Never add `Claude-Session` to the git commit
- Always use **Conventional Commits** style, typically: `fix`, `feat`, `tidy`, `refactor`, `docs`.
