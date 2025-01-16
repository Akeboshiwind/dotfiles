{ config, pkgs, userLib, ... }:

{
  home.packages = with pkgs; [
    git
  ];

  home.file = {
    ".zsh/git.zsh".source = ./.zsh/git.zsh;
    ".gitconfig".source = ./.gitconfig;
  };
}
