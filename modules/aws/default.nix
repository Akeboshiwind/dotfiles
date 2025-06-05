{ user, ... }:
{ config, pkgs, ... }:

{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      awscli2
      aws-vault
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix" "README.md" ".gitignore"]; }
    ];
  };
}
