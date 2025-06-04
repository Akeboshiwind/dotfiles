{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    awscli2
    aws-vault
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix" "README.md" ".gitignore"]; }
  ];
}
