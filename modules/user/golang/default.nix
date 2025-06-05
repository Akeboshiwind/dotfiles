{ user, ... }:
{ config, pkgs, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      # golang

      # Requirements:
      coreutils
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
