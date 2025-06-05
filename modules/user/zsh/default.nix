{ user, ... }:
{ config, pkgs, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      zsh
      zsh-syntax-highlighting
    ];
  };

  home-manager.users."${user}" = {
    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
