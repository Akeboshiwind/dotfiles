{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rustup
    
    # llvm
    # python3
    cmake
    openssl
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["default.nix"]; }
  ];
}
