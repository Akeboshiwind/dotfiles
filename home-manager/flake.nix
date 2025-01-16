{
  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
    in {
      homeConfigurations."osm" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # NOTE: To learn about the overrides convention:
        # https://nix.dev/tutorials/callpackage.html

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [
          ./home.nix

          # >> Shell
          #../zsh/home.nix
          ../fzf/home.nix
          ../fish/home.nix
          ../bash/home.nix
          ../tmux/home.nix

          # >> Editor
          ../nvim/home.nix
          ../vim/home.nix

          # >> Tools
          ../terraform/home.nix
          ../zoxide/home.nix
          ../ssh/home.nix
          ../git/home.nix
          ../gpg/home.nix
          ../bin/home.nix
          ../aws/home.nix

          # >> Apps
          ../alacritty/home.nix

          # >> Language
          ../clojure/home.nix
          #../rust/home.nix
          #../python/home.nix
          #../golang/home.nix
        ];

        extraSpecialArgs = {
          userLib = {
            # Adapted from: https://lazamar.co.uk/nix-versions
            # Use the above to find the right rev
            withRevision = ({ pkg, rev, url ? "https://github.com/NixOS/nixpkgs/", ref ? "refs/heads/nixpkgs-unstable" }: let
              versionPkgs = import (builtins.fetchGit {
                name = "${pkg}-from-${rev}";
                url = url;
                ref = ref;
                rev = rev;
              }) {
                inherit system;
              };
            in versionPkgs.${pkg});
          };
        };
      };
    };
}
