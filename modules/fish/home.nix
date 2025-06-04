{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fish
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
