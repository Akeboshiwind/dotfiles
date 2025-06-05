{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Core tools needed everywhere

  imports = withUser user [
    # >> Terminal setup
    ../modules/tmux
    #../modules/zsh
    ../modules/fish
    ../modules/bash

    # >> Editor
    ../modules/nvim
    ../modules/vim

    # >> Tools
    ../modules/git
    ../modules/ssh
    ../modules/gpg
    ../modules/fzf
    ../modules/zoxide
    ../modules/bin
  ];
}
