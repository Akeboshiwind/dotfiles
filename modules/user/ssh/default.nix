{ user, ... }:
{ config, pkgs, ... }:

{
  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
