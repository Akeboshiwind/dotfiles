{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh
    zsh-syntax-highlighting
  ];

  home.file = {
    ".zsh" = {
      source = ./.zsh;
      recursive = true;
    };
    ".zshrc".source = ./.zshrc;
  };
}
