{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Fun stuff :D

  homebrew.casks = [
    "godot"
    "telegram"
  ];

  imports = withUser user [
    ../modules/user/llm
    ../modules/user/cursor
  ];
}
