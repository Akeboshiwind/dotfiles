{ inputs, ... }:
{
  imports = [
    ../modules/system/home-manager
    ../modules/system/homebrew
    ../users/osm.nix
    ../users/personal.nix
  ];
}
