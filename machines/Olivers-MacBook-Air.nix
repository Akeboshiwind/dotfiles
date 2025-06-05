{ inputs, ... }: let
  system = "aarch64-darwin";
  nix-pin = inputs.nix-pin;
  lib = inputs.nixpkgs.lib;
in
{
  _module.args = {
    inherit system nix-pin;
  };

  imports = [
    ../modules/system/home-manager
    ../modules/system/homebrew
    ../users/osm.nix
    ../users/personal.nix
  ];
}
