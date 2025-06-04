{ config, pkgs, userLib, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["default.nix"]; }
    #{ source = ./.gitconfig; }
  ];
}
