{ user, ... }:
{ config, pkgs, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      zoxide
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
