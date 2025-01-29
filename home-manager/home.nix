{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Required by Home Manager
  home.username = "osm";
  home.homeDirectory = "/Users/osm";

  # NOTE: Only change when the changelog says to
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # If you want to use this then you have to manually source 'hm-session-vars.sh'
  #home.sessionVariables = { };
}
