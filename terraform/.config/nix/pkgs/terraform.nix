{ pkgs, lib, ... }: with pkgs; [
  (lib.withRevision {
    name = "terraform";
    rev = "c2c0373ae7abf25b7d69b2df05d3ef8014459ea3";
  })
]
