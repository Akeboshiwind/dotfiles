{ config, pkgs, userLib, ... }:

{
  home.packages = with pkgs; [
    git
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
    #{ source = ./.gitconfig; }
  ];
}
