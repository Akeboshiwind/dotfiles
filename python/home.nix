{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    poetry

    python314
  ];

  home.file = {
    ".zsh/completion/_poetry".source = ./.zsh/completion/_poetry;
    ".zsh/poetry.zsh".source = ./.zsh/poetry.zsh;
    ".zsh/pyenv.zsh".source = ./.zsh/pyenv.zsh;
  };
}
