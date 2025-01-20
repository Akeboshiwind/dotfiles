{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    openjdk17-bootstrap #  temurin-bin-17
    clojure
    babashka
    clj-kondo
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
