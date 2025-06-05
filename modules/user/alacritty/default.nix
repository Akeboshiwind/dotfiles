{ user, ... }:
{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
      nerd-fonts.meslo-lg
  ];

  users.users."${user}" = {
    packages = with pkgs; [
      alacritty
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
