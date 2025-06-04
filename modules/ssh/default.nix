{ config, pkgs, ... }:

{
  osm.home.folders = [
    { source = ./.; exclude = ["default.nix"]; }
  ];
}
