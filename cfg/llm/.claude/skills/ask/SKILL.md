---
name: ask
description: Raise a PR for the current branch for review and leave the worktree in place. Use when the user says "/ask".
disable-model-invocation: true
---

# Ask

A PR that waits for review.

1. **Prepare.** Commit all work; the tree MUST be clean.
   Fetch `<remote>` — `upstream` if it exists, else `origin` — and rebase onto `<remote>/<base>`, its default branch: parallel work merges often. On a conflict, stop and report.
2. **Push**: `git push`.
3. **Open the PR** on `<remote>` against `<base>`, and report its URL.
