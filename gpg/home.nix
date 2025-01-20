{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    gnupg
    pinentry_mac
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix" ".gitignore"]; }
  ];
}
