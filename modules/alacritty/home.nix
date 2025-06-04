{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    alacritty

    nerd-fonts.meslo-lg
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
