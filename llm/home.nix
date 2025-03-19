{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
