{ inputs, ... }: let
  system = "aarch64-darwin";
  nix-pin = inputs.nix-pin;
  lib = inputs.nixpkgs.lib;
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../users/osm.nix
    ../users/personal.nix
  ];
  home-manager.extraSpecialArgs = {
    userLib = (import ../modules/home-manager/lib/user.nix { inherit lib system; });
    inherit system;
    inherit nix-pin;
  };
  home-manager.sharedModules = [
    ../modules/home-manager/osm-files.nix
    ../modules/home-manager/osm-symlinks.nix

    # >> Shell
    #../modules/zsh
    ../modules/fzf
    ../modules/fish
    ../modules/bash
    ../modules/tmux

    # >> Editor
    ../modules/nvim
    ../modules/vim

    # >> Tools
    ../modules/terraform
    ../modules/zoxide
    ../modules/ssh
    ../modules/git
    ../modules/gpg
    ../modules/bin
    ../modules/aws
    ../modules/llm

    # >> Apps
    ../modules/alacritty

    # >> Language
    ../modules/clojure
    #../modules/rust
    #../modules/python
    #../modules/golang
  ];
}
