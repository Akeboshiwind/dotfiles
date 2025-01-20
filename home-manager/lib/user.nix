{ lib, system, ... }:

{
  # Adapted from: https://lazamar.co.uk/nix-versions
  # Use the above to find the right rev
  withRevision = ({ pkg, rev, url ? "https://github.com/NixOS/nixpkgs/", ref ? "refs/heads/nixpkgs-unstable" }: let
    versionPkgs = import (builtins.fetchGit {
      name = "${pkg}-from-${rev}";
      url = url;
      ref = ref;
      rev = rev;
    }) {
      inherit system;
    };
  in versionPkgs.${pkg});
}
