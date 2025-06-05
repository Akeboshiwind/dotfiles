{ user, ... }:
{ config, pkgs, ... }:

{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      bash

      # Addons
      bash-completion
      fzf
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
