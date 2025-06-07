{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Fun stuff :D

  imports = withUser user [
    ../modules/user/llm
    ../modules/user/cursor
  ];
}
