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
    userLib = (import ../home-manager/lib/user.nix { inherit lib system; });
    inherit system;
    inherit nix-pin;
  };
  home-manager.sharedModules = [
    ../home-manager/osm-files.nix
    ../home-manager/osm-symlinks.nix
    #../home-manager/home.nix

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
    ../llm/home.nix

    # >> Apps
    ../alacritty/home.nix

    # >> Language
    ../clojure/home.nix
    #../rust/home.nix
    #../python/home.nix
    #../golang/home.nix
  ];
  home-manager.users."osm" = (homeCfg { username = "osm"; homeDirectory = "/Users/osm"; });
  home-manager.users."personal" = (homeCfg { username = "personal"; homeDirectory = "/Users/personal"; });
}
