{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    openjdk17-bootstrap #  temurin-bin-17
    clojure
    babashka
    clj-kondo
  ];

  # TODO: Fix, I get permission errors for some reason
  #home.activation = {
  #  linkOpenJDK = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #    run rm /Library/Java/JavaVirtualMachines/*
  #    run ln -sfv "${pkgs.openjdk17-bootstrap}" "/Library/Java/JavaVirtualMachines/"
  #  '';
  #};

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
