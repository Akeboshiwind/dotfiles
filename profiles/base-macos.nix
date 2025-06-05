{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Desktop-specific tools for macOS

  imports = withUser user [
    # >> Terminal setup
    ../modules/alacritty
  ];
}
