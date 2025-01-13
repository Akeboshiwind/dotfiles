{
  description = "The flake that describes packages used by";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # To support multiple systems
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;

        # Load dependencies from config files
        pkgsDir = ~/.config/nix/pkgs;
        packages = lib.pipe pkgsDir [
          builtins.readDir
          builtins.attrNames # Get keys
          # Run `import` on all the found files
          (builtins.map (name: import (pkgsDir + "/${name}") { inherit pkgs; }))
          lib.flatten
          lib.unique
        ];
      in {
        packages.default = pkgs.buildEnv {
          # A name is required for some reason 🤷
          name = "packages";
          paths = packages;
        };
      }
    );
}
