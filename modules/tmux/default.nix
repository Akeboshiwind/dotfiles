{ user, ... }:
{ config, pkgs, ... }:

{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      tmux
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
