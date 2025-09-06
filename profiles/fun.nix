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
    "musescore"
  ];

  homebrew.masApps = {
    #"Xcode" = 497799835;
  };
}
