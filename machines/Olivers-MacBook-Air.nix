{ inputs, ... }: let
  system = "aarch64-darwin";
  nix-pin = inputs.nix-pin;
  lib = inputs.nixpkgs.lib;
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../users/osm.nix
    ../users/personal.nix
  ];
  home-manager.extraSpecialArgs = {
    userLib = (import ../modules/home-manager/lib/user.nix { inherit lib system; });
    inherit system;
    inherit nix-pin;
  };
  home-manager.sharedModules = [
    ../modules/home-manager/osm-files.nix
    ../modules/home-manager/osm-symlinks.nix
  ];
}
