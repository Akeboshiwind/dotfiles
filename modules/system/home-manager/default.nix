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
      ./osm-files.nix
      ./osm-symlinks.nix
    ];
  };
}