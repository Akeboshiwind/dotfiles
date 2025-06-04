{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    zoxide
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
