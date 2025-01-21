{ config, pkgs, userLib, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
    #{ source = ./.gitconfig; }
  ];
}
