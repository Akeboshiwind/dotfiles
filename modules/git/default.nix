{ user, ... }:
{ config, pkgs, userLib, ... }:

{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      git
      git-lfs
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
      #{ source = ./.gitconfig; }
    ];
  };
}
