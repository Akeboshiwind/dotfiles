{ config, pkgs, ... }:

{
  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
