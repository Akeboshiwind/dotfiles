{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    poetry

    python314
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["default.nix" "README.md"]; }
  ];
}
