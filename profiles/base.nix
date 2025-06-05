{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Core tools needed everywhere

  imports = withUser user [
    # >> Terminal setup
    ../modules/user/tmux
    #../modules/user/zsh
    ../modules/user/fish
    ../modules/user/bash

    # >> Editor
    ../modules/user/nvim
    ../modules/user/vim

    # >> Tools
    ../modules/user/git
    ../modules/user/ssh
    ../modules/user/gpg
    ../modules/user/fzf
    ../modules/user/zoxide
    ../modules/user/bin
  ];
}
