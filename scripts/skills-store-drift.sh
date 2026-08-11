#!/bin/sh
# Exit 0 when the shared sbx skills store already matches cfg/llm/skills.
#
# The store is a copy that sandboxes mount, not a link, so it goes stale
# whenever a skill changes. The comparison is against the store itself: the
# host symlinks match the repository by construction, so they prove nothing.
#
# Repository → store only. The store is shared with every other agent sbx
# imports from, so a skill present there and absent here is somebody else's and
# must not read as drift.
#
# Store path per `sbx skills import` output on macOS. That command is still
# marked EXPERIMENTAL, so should the path move, this reports drift forever and
# the import — which is idempotent — runs on every apply.

command -v sbx >/dev/null 2>&1 || exit 0

store="$HOME/Library/Application Support/com.docker.sandboxes/sandboxes/agent-skills"

for skill in cfg/llm/skills/*/; do
  diff -r "$skill" "$store/$(basename "$skill")" >/dev/null 2>&1 || exit 1
done
