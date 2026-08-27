#!/bin/sh
# Exit 0 when a template is up to date: still in the sandbox runtime's image
# store, and built after every spec it was built from.
#
# Usage: sbx-template-fresh.sh <name> <kit name>...
#
# A stamp file rather than the template's own timestamp: `sbx template ls` output
# is not a contract, so it is read only for the name.
set -eu

name=$1
shift   # the rest are kit names under cfg/sbx/kits

# From this script's location, so the answer does not depend on $PWD — the same
# reason sbx-build-template.sh resolves kits this way.
repo=$(cd "$(dirname "$0")/.." && pwd)

stamp="$HOME/.cache/sbx-templates/$name.stamp"
[ -f "$stamp" ] || exit 1

# `sbx reset` clears the image store and leaves the stamp behind. A command that
# fails outright means we cannot tell, and guessing wrong costs a rebuild on
# every apply.
if sbx template ls >/dev/null 2>&1; then
  sbx template ls | grep -q "$name" || exit 1
fi

# Only spec.yaml is compared. A kit's files/ tree is copied from the kit at every
# sandbox create, so what a template baked there is never read — and CLAUDE.md,
# the file that changes most, lives there.
#
# find rather than `-nt`, so a spec and a stamp sharing an mtime reads as fresh
# instead of rebuilding forever.
specs=""
for kit in "$@"; do
  specs="$specs $repo/cfg/sbx/kits/$kit/spec.yaml"
done

# shellcheck disable=SC2086
[ -z "$(find $specs -newer "$stamp" -print -quit)" ]
