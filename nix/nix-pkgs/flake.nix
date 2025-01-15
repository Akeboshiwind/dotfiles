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
        lib = nixpkgs.lib // {
          # Adapted from: https://lazamar.co.uk/nix-versions
          # Use the above to find the right rev
          withRevision = ({ name, rev, url ? "https://github.com/NixOS/nixpkgs/", ref ? "refs/heads/nixpkgs-unstable" }: let
            versionPkgs = import (builtins.fetchGit {
              name = "${name}-revision-${rev}";
              url = url;
              ref = ref;
              rev = rev;
            }) {};
          in versionPkgs.${name});
        };

        # Load dependencies from config files
        pkgsDir = ~/.config/nix/pkgs;
        packages = lib.pipe pkgsDir [
          builtins.readDir
          builtins.attrNames # Get keys
          (builtins.map (name: pkgsDir + "/${name}"))
          # Run `import` on all the found files
          (builtins.map (path: import path { inherit pkgs; inherit lib; }))
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
