{ inputs, ... }: let
  system = "aarch64-darwin";
  nix-pin = inputs.nix-pin;
  lib = inputs.nixpkgs.lib;
  homeCfg = { username, homeDirectory }:
    { config, pkgs, lib, ... }:
    {
      # Required by Home Manager
      home.username = username;
      home.homeDirectory = homeDirectory;
    
      # NOTE: Only change when the changelog says to
      home.stateVersion = "24.11";
    
      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;
    
      # Allow installing unfree packages
      nixpkgs.config.allowUnfree = true;
    
      # Link Applications into the user environment
      #targets.darwin.linkApps.directory = "Applications";
    
      # If you want to use this then you have to manually source 'hm-session-vars.sh'
      #home.sessionVariables = { };
    };
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
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
  home-manager.users."osm" = (homeCfg { username = "osm"; homeDirectory = "/Users/osm"; });
  home-manager.users."personal" = (homeCfg { username = "personal"; homeDirectory = "/Users/personal"; });
}
