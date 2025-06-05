{ user, ... }:
{ config, pkgs, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
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
      babashka
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
