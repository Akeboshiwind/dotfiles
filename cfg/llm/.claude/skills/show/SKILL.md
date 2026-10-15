---
name: show
description: Raise a PR for the current branch, merge it once CI passes without waiting for review, then remove its worktree and pull the base in the main checkout. Use when the user says "/show".
---

# Show

A PR for the record, merged without waiting for review.

1. **Prepare.** Commit all work; the tree MUST be clean.
   Fetch `<remote>` — `upstream` if it exists, else `origin` — and rebase onto `<remote>/<base>`, its default branch: parallel work merges often. On a conflict, stop and report.
2. **Push**: `git push`.
3. **Open the PR** on `<remote>` against `<base>`, then `gh pr checks <n> --watch`.
   On a failure, stop and report; leave the PR open. No checks configured: carry on.
4. **Merge** with `gh pr merge <n> --merge`, then `git push origin --delete <branch>`.
   Not `--delete-branch`: it checks out the base locally, which fails in a worktree.
5. **Clean up.**
   Leave the worktree first: `ExitWorktree` with `action: "remove"` if this session entered it, else `cd` to the main checkout and `git worktree remove <path>`.
   The isolation guard refuses `git -C <main checkout>` from inside a worktree, so the rest runs in the main checkout.
   On the base with a clean tree, `git pull --ff-only <remote> <base>`; otherwise report that it was not pulled, and why.
   If the branch still exists, `git branch -d <branch>`.
