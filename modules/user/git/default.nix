{ user, ... }:
{ config, pkgs, userLib, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      git
      git-lfs
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
      #{ source = ./.gitconfig; }
    ];
  };
}
