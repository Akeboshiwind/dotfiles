{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Stuff for llms

  imports = withUser user [
    ../modules/user/llm
    ../modules/user/cursor
  ];
}
