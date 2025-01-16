{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fish
  ];

  home.file = {
    ".config/fish" = {
      source = ./.config/fish;
      recursive = true;
    };
  };
}
