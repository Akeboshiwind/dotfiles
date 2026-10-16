#!/usr/bin/env bash
# git-crypt looks for its key under `git rev-parse --git-dir`, which in a
# worktree is .git/worktrees/<name>, not .git. Point the filters at the
# common dir instead. `git-crypt unlock` resets these, so syn re-applies them.
set -euo pipefail

key='--key-file "$(git rev-parse --git-common-dir)/git-crypt/keys/default"'

git config filter.git-crypt.clean  "\"git-crypt\" clean $key"
git config filter.git-crypt.smudge "\"git-crypt\" smudge $key"
git config diff.git-crypt.textconv "\"git-crypt\" diff $key"
