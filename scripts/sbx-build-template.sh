#!/bin/sh
# Snapshot a throwaway sandbox into a template, so real sandboxes boot with the
# kits' installs already done. The kits stay the definition of what gets
# installed — deleting a template costs startup time, not correctness.
#
# Usage: sbx-build-template.sh <name> <kit name>...
#
# Built from the upstream image, not from the previous template. A rebuild is
# then slow but clean, and `sbx template rm` below can drop the old tag without
# pulling the ground out from under the sandbox being saved.
#
# A workspace per template: a sandbox is keyed on its workspace, so a shared one
# would make the second build reconnect to the first build's sandbox instead of
# creating anything.
set -eu

name=$1
shift   # the rest are kit names under cfg/sbx/kits

# Kits are named, not passed as paths, so sbx gets an absolute one — a relative
# --kit would depend on whose working directory resolves it. Derived from this
# script's own location rather than $PWD, so it does not rely on syn's `cd`.
repo=$(cd "$(dirname "$0")/.." && pwd)
kits=""
for kit in "$@"; do
  kits="$kits --kit $repo/cfg/sbx/kits/$kit"
done

box="build-$name"
cache="$HOME/.cache/sbx-templates"
work="$cache/$name-workspace"
mkdir -p "$work"

# A build interrupted last time leaves the box behind, and `sbx create` would
# then reconnect to it rather than apply the kits again.
sbx rm --force "$box" >/dev/null 2>&1 || true

# $kits unquoted on purpose: it has to split into separate --kit arguments.
# shellcheck disable=SC2086
sbx create --name "$box" $kits claude "$work"
sbx stop "$box"

# Same tag, so the old one has to go first. If `save` then fails, there is no
# template until the next apply, and ct fails loudly rather than silently
# building from a stale one.
sbx template rm "$name:latest" >/dev/null 2>&1 || true
sbx template save "$box" "$name:latest"

sbx rm --force "$box"

touch "$cache/$name.stamp"
