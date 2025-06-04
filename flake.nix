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
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-pin }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake ~/dotfiles/nix-darwin
    darwinConfigurations."Olivers-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [
        ./modules/nix-darwin
        ./machines/Olivers-MacBook-Air.nix
      ];
      specialArgs = { 
        inherit self;
        inherit inputs;
      };
    };
  };
}
