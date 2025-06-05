{ user, ... }:
{ config, pkgs, userLib, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      fzf
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
