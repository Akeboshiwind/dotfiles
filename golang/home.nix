{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # golang

    # Requirements:
    coreutils
  ];

  home.file = {
    ".zsh/golang.zsh".source = ./.zsh/golang.zsh;
  };
}
