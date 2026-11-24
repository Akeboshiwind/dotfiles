---
name: settle
description: Clean the workspace up after work has landed — worktree removed, base pulled, branch deleted, tabs and watches released — then settle this T3 Code thread. Use when the user says "/settle", "settle this", or "we're done here".
---

# Settle

The session is finished with. Leave nothing behind, then close the chat.

`/settle` **lands nothing.** `/ship`, `/show` and `/ask` land work; this one only tidies up after them. If there is work still to land, stop and say which command to reach for.

1. **Check there is nothing to lose.** All three MUST hold; on any failure, stop and report which:
   - the tree is clean — `git status --porcelain` is empty;
   - every commit on the branch is reachable from `<remote>/<base>` — `git log --oneline <remote>/<base>..HEAD` is empty, after fetching `<remote>` (`upstream` if it exists, else `origin`);
   - the branch has no open PR — `gh pr list --head <branch> --state open`.

   Already on `<base>` with nothing of its own: there is no branch to clean up, so skip to step 3.

2. **Clean up the workspace.**
   Leave the worktree first: `ExitWorktree` with `action: "remove"` if this session entered it, else `cd` to the main checkout and `git worktree remove <path>` — `t3_worktree_status` names both.
   The isolation guard refuses `git -C <main checkout>` from inside a worktree, so the rest runs in the main checkout.
   On the base with a clean tree, `git pull --ff-only <remote> <base>`; otherwise report that it was not pulled, and why.
   If the branch still exists, `git branch -d <branch>` — `-d`, never `-D`: a refusal means step 1 missed something.
   Leave the stash alone. The stack is shared with every other worktree, so an entry this session did not push is not its to drop.

3. **Release what this session is holding.** Each is a no-op if there is nothing to release:
   `unwatch_pull_request` on any PR it watches, `task_cancel` on any delegate still running, `t3_preview_close` on any tab it opened.

4. **Settle the thread.** Report the cleanup in one line, then `t3_thread_organize` with `action: "settle"` as the **last call of the turn** — it applies at turn end, and a queued message or a failed turn leaves the thread active.
