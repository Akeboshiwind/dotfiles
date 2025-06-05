{ user, ... }:
{ config, pkgs, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      awscli2
      aws-vault
    ];
  };

  home-manager.users."${user}" = {
    osm.home.folders = [
      { source = ./.; exclude = ["default.nix" "README.md" ".gitignore"]; }
    ];
  };
}
