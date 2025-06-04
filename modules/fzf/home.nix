{ config, pkgs, userLib, ... }:

{
  home.packages = with pkgs; [
    fzf
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
