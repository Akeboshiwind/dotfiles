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

2. **Clean up the workspace.** `t3_worktree_status` names this thread's `worktreePath` and `projectWorkspaceRoot`.

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
   - `-d`, never `-D`: a refusal means step 1 missed something.

   If the pull cannot fast-forward, drop it from the chain and report why; the rest still runs.

   T3's storage sweep removes abandoned worktrees but **never deletes branches**, so this step is the only thing standing between the project and an endless list of `t3/*` refs.

   Leave the stash alone. The stack is shared with every other worktree, so an entry this session did not push is not its to drop.

3. **Release what this session is holding.** Each is a no-op if there is nothing to release:
   `unwatch_pull_request` on any PR it watches, `task_cancel` on any delegate still running, `t3_preview_close` on any tab it opened.

4. **Settle the thread.** Report the cleanup in one line, then `t3_thread_organize` with `action: "settle"` as the **last call of the turn** — it applies at turn end, and a queued message or a failed turn leaves the thread active.
