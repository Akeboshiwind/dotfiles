#!/usr/bin/env bash
# WorktreeCreate hook: Claude Code's own creation skips filter drivers (since
# v2.1.247, https://code.claude.com/docs/en/worktrees.md), which leaves
# secrets.edn as ciphertext that a later `commit -a` encrypts again.
# Stdin carries {"name": …}; the last stdout line must be the worktree path.
set -euo pipefail

name=$(jq -r .name)
root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
dir=$root/.claude/worktrees/$name

git -C "$root" fetch -q origin >&2 || true
git -C "$root" worktree add -q -b "worktree-$name" "$dir" origin/HEAD >&2 || {
  git -C "$root" branch -q -D "worktree-$name" >&2 || true
  echo "worktree add failed; if git-crypt's smudge failed, run \`syn --apply\` to repoint its filters" >&2
  exit 1
}
echo "$dir"
