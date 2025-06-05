{ user, ... }:
{ config, pkgs, ... }:

{
  home-manager.users."${user}" = {
    home.packages = with pkgs; [
      poetry # use uv instead?

      python314
    ];

    osm.home.folders = [
      { source = ./.; exclude = ["default.nix" "README.md"]; }
    ];
  };
}
