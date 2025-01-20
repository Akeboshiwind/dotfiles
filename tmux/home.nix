{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    tmux
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
