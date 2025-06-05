{ user, ... }:
{ config, pkgs, ... }:

{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      gnupg
      pinentry_mac
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix" ".gitignore"]; }
    ];
  };
}
