{ inputs, lib, system, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      fs = (import ../../../lib/fs.nix { inherit lib system; });
    };
    sharedModules = [
      ./custom-folders.nix
      ./custom-livelinks.nix
    ];
  };
}