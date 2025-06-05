{ user, ... }:
{ config, pkgs, userLib, ... }:

{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      fzf
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
