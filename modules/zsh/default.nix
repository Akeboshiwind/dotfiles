{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh
    zsh-syntax-highlighting
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["default.nix"]; }
  ];
}
