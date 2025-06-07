{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Desktop-specific tools for macOS

  imports = withUser user [
    # >> Terminal setup
    ../modules/user/alacritty

    ../modules/user/macos-gui
    ../modules/user/macos-config
  ];
}
