{ user, ... }:
{ config, pkgs, userLib, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      fzf
    ];
  };

  home-manager.users."${user}" = {
    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
