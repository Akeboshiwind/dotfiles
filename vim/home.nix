{ config, pkgs, ... }:

{
  home.file = {
    ".vimrc".source = ./.vimrc;
  };
}
