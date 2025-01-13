{ pkgs }: with pkgs; 
let 
  # https://lazamar.co.uk/nix-versions/?package=terraform&version=1.2.9&fullName=terraform-1.2.9&keyName=terraform&revision=c2c0373ae7abf25b7d69b2df05d3ef8014459ea3&channel=nixpkgs-unstable#instructions
  terraformPkgs = import (builtins.fetchGit {
    # Descriptive name to make the store path easier to identify
    name = "my-old-revision";
    url = "https://github.com/NixOS/nixpkgs/";
    ref = "refs/heads/nixpkgs-unstable";
    rev = "c2c0373ae7abf25b7d69b2df05d3ef8014459ea3";
  }) {};
in [
  terraformPkgs.terraform
]
