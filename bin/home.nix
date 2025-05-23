{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # TODO: Update scripts to either just use sh or babashka
    bash
    coreutils
    git
    tree
    jq
    ffmpeg
    stow
    help2man
    htop
    nmap
    imagemagickBig
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
