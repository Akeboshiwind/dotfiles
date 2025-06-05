{ inputs, lib, system, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      userLib = (import ./lib/user.nix { inherit lib system; });
    };
    sharedModules = [
      ./custom-folders.nix
      ./custom-livelinks.nix
    ];
  };
}