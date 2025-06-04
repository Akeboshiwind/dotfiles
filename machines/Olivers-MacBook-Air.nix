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
    #../modules/home-manager/home.nix

    # >> Shell
    #../modules/zsh/home.nix
    ../modules/fzf/home.nix
    ../modules/fish/home.nix
    ../modules/bash/home.nix
    ../modules/tmux/home.nix

    # >> Editor
    ../modules/nvim/home.nix
    ../modules/vim/home.nix

    # >> Tools
    ../modules/terraform/home.nix
    ../modules/zoxide/home.nix
    ../modules/ssh/home.nix
    ../modules/git/home.nix
    ../modules/gpg/home.nix
    ../modules/bin/home.nix
    ../modules/aws/home.nix
    ../modules/llm/home.nix

    # >> Apps
    ../modules/alacritty/home.nix

    # >> Language
    ../modules/clojure/home.nix
    #../modules/rust/home.nix
    #../modules/python/home.nix
    #../modules/golang/home.nix
  ];
}
