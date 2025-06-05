{ user, ... }:
{ config, pkgs, ... }:
{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      claude-code
      llm
      repomix
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
