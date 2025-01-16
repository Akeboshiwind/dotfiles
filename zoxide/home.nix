{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    zoxide
  ];

  home.file = {
    ".zsh/zoxide.zsh".source = ./.zsh/zoxide.zsh;
    ".config/fish/conf.d/zoxide.fish".source = ./.config/fish/conf.d/zoxide.fish;
  };
}
