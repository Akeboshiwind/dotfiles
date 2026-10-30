#!/usr/bin/env bash
# Links each JDK mise has installed into the folder /usr/libexec/java_home
# scans (and so Gradle's toolchain detection), and removes the links it made
# for JDKs mise no longer has.
#   java-home.sh           apply
#   java-home.sh --check   exit 1 if applying would change anything
# $DOTFILES_SCRIPT_STATE holds the versions this script has linked, one per line.
set -euo pipefail

installs="${JAVA_INSTALLS_DIR:-${MISE_DATA_DIR:-$HOME/.local/share/mise}/installs/java}"
vms="${JAVA_VM_DIR:-$HOME/Library/Java/JavaVirtualMachines}"
state="${DOTFILES_SCRIPT_STATE:?run by syn, which provides the state file}"

installed() {
  local dir
  for dir in "$installs"/*; do
    # mise's version aliases (temurin-21, latest, ...) are symlinks to real installs
    if [ -d "$dir/Contents" ] && [ ! -L "$dir" ]; then basename "$dir"; fi
  done
}

link_of() { echo "$vms/$1.jdk/Contents"; }
source_of() { echo "$installs/$1/Contents"; }
ours() { [ -L "$(link_of "$1")" ] && [ "$(readlink "$(link_of "$1")")" = "$(source_of "$1")" ]; }

wanted=$(installed)
previous=$(cat "$state")
is_wanted() { grep -qxF -- "$1" <<<"$wanted"; }

if [ "${1:-}" = --check ]; then
  while read -r v; do
    if [ -n "$v" ] && ! ours "$v"; then exit 1; fi
  done <<<"$wanted"
  while read -r v; do
    if [ -n "$v" ] && ! is_wanted "$v" && ours "$v"; then exit 1; fi
  done <<<"$previous"
  exit 0
fi

while read -r v; do
  if [ -n "$v" ] && ! is_wanted "$v" && ours "$v"; then
    rm "$(link_of "$v")"
    rmdir "$vms/$v.jdk" 2>/dev/null || true
  fi
done <<<"$previous"

: >"$state"
while read -r v; do
  [ -n "$v" ] || continue
  if ! ours "$v"; then
    if [ -e "$(link_of "$v")" ] || [ -L "$(link_of "$v")" ]; then
      echo "$(link_of "$v") exists and isn't a link to $(source_of "$v"); leaving it" >&2
      exit 1
    fi
    mkdir -p "$vms/$v.jdk"
    ln -s "$(source_of "$v")" "$(link_of "$v")"
  fi
  echo "$v" >>"$state"
done <<<"$wanted"
