---
name: ship
description: Land the current branch straight on the base branch with no PR, then remove its worktree and pull the base in the main checkout. Use when the user says "/ship" or "ship it".
---

# Ship

Straight to the base branch, no review.

1. **Prepare.** Commit all work; the tree MUST be clean.
   Fetch `<remote>` — `upstream` if it exists, else `origin` — and rebase onto `<remote>/<base>`, its default branch: parallel work merges often. On a conflict, stop and report.
   Run the project's tests, if it has any; on a failure, stop and report.
2. **Push** to the base: `git push <remote> HEAD:refs/heads/<base>`.
   Rejected as non-fast-forward: fetch, rebase, rerun the tests and push again, once. A second rejection, stop and report.
3. **Report CI**, if the repo runs any on the base: `gh run list --branch <base> --limit 1`.
4. **Clean up.** `t3_worktree_status` names this thread's `worktreePath` and `projectWorkspaceRoot`.

   **Do not reach for `ExitWorktree`.** It only touches worktrees `EnterWorktree` made in this session; T3 bound this one at thread launch, so it is a silent no-op that reports success while the worktree stays on disk.

   Run the cleanup as a **single shell invocation**, in this order:

   ```bash
   cd <projectWorkspaceRoot> \
     && git pull --ff-only <remote> <base> \
     && git worktree remove <worktreePath> \
     && git branch -d <branch>
   ```

   The order is forced, and so is the single invocation:
   - the session's cwd is inside the worktree, so `cd` must come first — once the directory is gone, a later shell cannot start in it;
   - `git branch -d` refuses while the branch is checked out in a worktree, so the branch goes after the worktree;
   - `-d`, never `-D`: a refusal means the push in step 2 did not land what you think it did.

   If the pull cannot fast-forward, drop it from the chain and report why; the rest still runs.
