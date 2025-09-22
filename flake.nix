{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-pin.url = "github:akeboshiwind/nix-pin";

    # TODO: Switch to nix-homebrew when the following is fixed:
    #       https://github.com/zhaofengli/nix-homebrew/issues/96
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, neovim-nightly-overlay, ... }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake ~/dotfiles/nix-darwin
    darwinConfigurations."C19608" = nix-darwin.lib.darwinSystem {
      modules = [
        ./modules/system/nix-darwin
        ./machines/Olivers-MacBook-Air.nix
        {
          nixpkgs.overlays = [
            neovim-nightly-overlay.overlays.default
          ];
        }
      ];
      specialArgs = { 
        inherit self inputs system;
      };
    };

    checks.${system} = {
      tests = import ./lib/runPureTests.nix {
        inherit (pkgs) lib;
        inherit system;
        tests = 
          (import ./lib/fs.test.nix { inherit pkgs system; }) //
          (import ./modules/system/home-manager/lib/folders.test.nix { inherit pkgs system; });
      };
    };
  };
}
