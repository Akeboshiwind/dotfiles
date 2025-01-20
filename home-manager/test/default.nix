{ pkgs ? import <nixpkgs> {}, ... }:

let
  inherit (pkgs) lib;
  inherit (lib) runTests;
in
  runTests (
    (import ./user.nix { inherit lib; })
    // (import ./folders.nix { inherit lib; })
  )
