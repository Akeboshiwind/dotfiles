{ user, ... }:
{ config, pkgs, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      tmux
    ];
  };

  home-manager.users."${user}" = {
    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
