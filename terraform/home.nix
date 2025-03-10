{ config, pkgs, userLib, ... }:

{
  home.packages = with pkgs; [
    (userLib.withRevision {
      pkg = "terraform";
      rev = "c2c0373ae7abf25b7d69b2df05d3ef8014459ea3";
    })
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix"]; }
  ];
}
