{
  config,
  pkgs,
  lib,
  username,
  homeDirectory,
  ...
}:

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

  # If you want to use this then you have to manually source 'hm-session-vars.sh'
  #home.sessionVariables = { };
}
