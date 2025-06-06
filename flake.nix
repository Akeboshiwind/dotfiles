{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

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

  outputs = inputs@{ self, nixpkgs, nix-darwin, ... }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake ~/dotfiles/nix-darwin
    darwinConfigurations."Olivers-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [
        ./modules/system/nix-darwin
        ./machines/Olivers-MacBook-Air.nix
      ];
      specialArgs = { 
        inherit self inputs system;
      };
    };

    checks.${system} = {
      home-manager-tests = import ./lib/runPureTests.nix {
        inherit (pkgs) lib;
        inherit system;
        tests = 
          (import ./modules/system/home-manager/test/user.nix { inherit (pkgs) lib; inherit system; }) //
          (import ./modules/system/home-manager/test/folders.nix { inherit (pkgs) lib; inherit system; });
      };
    };
  };
}
