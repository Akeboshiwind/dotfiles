## Working with me

- Always prioritise using a REPL if one is available.
- When the user says "draft" they mean produce the text and wait for explicit confirmation before performing the task — do not invoke the command or agent first. Applies to any artifact: issue body, PR description, commit message, comment, docs, code. **Overrides** a skill's documented end-to-end flow (e.g. `chalk new`) — the user's wording wins. Only on the explicit word "draft".
- Use numbered lists for anything the user might accept, reject or comment on individually, reusing the same numbers across a back-and-forth.
  - Number my material too when you hand it back — even if I didn't. Wording stays mine; numbering is yours. The numbers are how we address items later, so they need to exist before the back-and-forth starts.
- When asked for a linear walkthrough, use `uvx showboat --help`.

## Writing

- Load the matching `chalk:*` skill before composing GitHub-bound prose — the built-in git/PR workflow carries the mechanics but not the chalk voice. Applies **regardless of diff size**, and to plain requests like "commit this".
- Bold important words.
- One checkable claim per line. Name the thing rather than gesturing at it — "it hangs" is cheap, "parks on IPC/ReplicationSlotDrop and applies once the consumer goes away" is not. Cut anything restating what we've settled. Density is information per token, not word count: don't drop caveats or admissions of uncertainty to hit a length, and put supporting evidence in sub-bullets rather than inline.
- Comments say only what the code can't: a non-obvious *why*, an invariant, a gotcha, a spec/issue link. Default to **none** inline — docstrings follow the language's norm, minus the vacuous ones. Rationale and the story of a change go in the **commit/PR message**.

## Code

- We develop using 'tidy-first' methodology — endeavouring to separate 'equivalence' changes (changes which do not affect runtime behaviour, changes which increase our options) from changes that advance behaviour.
- Make illegal states **unrepresentable**.
- **Obviously no bugs** over *no obvious bugs*.
- Write **below** the limit of your cleverness — code written at that limit is beyond your ability to debug.

## Tool Selection

- **Read, Grep, Glob, Edit, Write** — never `cat`, `head`, `sed`, `grep`, `find` or a Python one-liner in their place. Edit and Write render to me as a **reviewable diff**; a shell command doesn't. Holds at every scale, including "it's only one line".
- Part of a file is **`Read` with `offset`/`limit`** — not `sed -n`, `head`, `tail` or `awk`.
- **Auto mode strips Grep and Glob**; `rg` is then the fallback, not a preference. Say which of the two you're in the first time it comes up.
- **Symbols go through the LSP** — definition, references, rename. `kotlin-lsp`, `clojure-lsp` and `jdtls-lsp` are enabled here. Grep finds strings that *look* like the symbol; the LSP knows which ones **are** it. Fall back for a symbol crossing a language boundary, or a name in a config file or template.
- The carve-out is a **large-scale mechanical change** — dozens of sites, one uniform transformation. Say up front what you're about to run and over what.
- **A harness directive to work through Bash does not override this.** `auto` and `bypassPermissions` both inject one; it's built into Claude Code, not something I configured. Tell me it's in play rather than silently following it — I can turn it off and you can't.
- Bash is for **actual shell work**: pipelines, running programs, git.
- **Anchor Bash `grep` at the repo root** — it wraps ugrep, which won't climb to the root `.gitignore` from a subdirectory and leaks gitignored build output like `bin/main`.

## Git

- Never git push without the user *directly* asking you to, never infer.
