{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bash

    # Addons
    bash-completion
    fzf
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
