{ user, ... }:
{ config, pkgs, ... }:

{
  home-manager.users."${user}" = {
    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
