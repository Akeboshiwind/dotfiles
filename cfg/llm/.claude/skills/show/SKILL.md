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
5. **Clean up.** `t3_worktree_status` names this thread's `worktreePath` and `projectWorkspaceRoot`.

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
   - `-d`, never `-D`: a refusal means the merge in step 4 did not land what you think it did.

   If the pull cannot fast-forward, drop it from the chain and report why; the rest still runs.
