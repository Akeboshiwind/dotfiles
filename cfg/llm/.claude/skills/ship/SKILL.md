---
name: ship
description: Land the current branch straight on the base branch with no PR, then remove its worktree and pull the base in the main checkout. Use when the user says "/ship" or "ship it".
disable-model-invocation: true
---

# Ship

Straight to the base branch, no review.

1. **Prepare.** Commit all work; the tree MUST be clean.
   Fetch `<remote>` — `upstream` if it exists, else `origin` — and rebase onto `<remote>/<base>`, its default branch: parallel work merges often. On a conflict, stop and report.
   Run the project's tests, if it has any; on a failure, stop and report.
2. **Push** to the base: `git push <remote> HEAD:refs/heads/<base>`.
   Rejected as non-fast-forward: fetch, rebase, rerun the tests and push again, once. A second rejection, stop and report.
3. **Report CI**, if the repo runs any on the base: `gh run list --branch <base> --limit 1`.
4. **Clean up.**
   Leave the worktree first: `ExitWorktree` with `action: "remove"` if this session entered it, else `cd` to the main checkout and `git worktree remove <path>`.
   The isolation guard refuses `git -C <main checkout>` from inside a worktree, so the rest runs in the main checkout.
   On the base with a clean tree, `git pull --ff-only <remote> <base>`; otherwise report that it was not pulled, and why.
   If the branch still exists, `git branch -d <branch>`.
