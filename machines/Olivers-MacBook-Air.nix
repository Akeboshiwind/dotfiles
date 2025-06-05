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
    ../users/osm.nix
    ../users/personal.nix
  ];

  homebrew = {
    enable = true;
    user = "personal";
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    brews = [
      "mas" # To enable homebrew.masApps
    ];
  };
}
