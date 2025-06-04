{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code
    llm
    repomix
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
