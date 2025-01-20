{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # golang

    # Requirements:
    coreutils
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
