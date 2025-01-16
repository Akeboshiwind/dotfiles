{ config, pkgs, userLib, ... }:

{
  home.packages = with pkgs; [
    fzf
  ];

  home.file = {
    ".zsh/fzf.zsh".source = ./.zsh/fzf.zsh;
    ".config/fish/conf.d/fzf.fish".source = ./.config/fish/conf.d/fzf.fish;
  };
}
