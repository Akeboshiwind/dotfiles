{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    bash

    # Addons
    bash-completion
    fzf
  ];

  home.file = {
    ".bashrc".source = ./.bashrc;
    ".bash_profile".source = ./.bash_profile;
    ".bash_aliases".source = ./.bash_aliases;
  };
}
