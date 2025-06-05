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
    inputs.home-manager.darwinModules.home-manager
    ../users/osm.nix
    ../users/personal.nix
  ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      userLib = (import ../modules/system/home-manager/lib/user.nix { inherit lib system; });
    };
    sharedModules = [
      ../modules/system/home-manager/osm-files.nix
      ../modules/system/home-manager/osm-symlinks.nix
    ];
  };

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
