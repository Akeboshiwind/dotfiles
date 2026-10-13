## Working with me

- When asked for a linear walkthrough, use `uvx showboat --help`.

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
- **Obviously no bugs** over *no obvious bugs*.
- **Simple** (not braided) over easy (near at hand)
- Write **below** the limit of your cleverness — code written at that limit is beyond your ability to debug.

## Git

- Never add `Claude-Session` to the git commit
- Always use **Conventional Commits** style, typically: `fix`, `feat`, `tidy`, `refactor`, `docs`.
