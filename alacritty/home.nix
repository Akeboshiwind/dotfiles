{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    alacritty

    nerd-fonts.meslo-lg
  ];

  home.file = {
    ".config/alacritty".source = ./.config/alacritty;
  };
}
