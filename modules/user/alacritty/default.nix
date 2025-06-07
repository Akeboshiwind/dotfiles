{ user, ... }:
{ config, pkgs, ... }:

{
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  homebrew.casks = [
    "alacritty"
  ];

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
