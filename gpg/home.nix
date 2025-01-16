{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    gnupg
    pinentry_mac
  ];

  home.file = {
    ".gnupg".source = ./.gnupg;
  };
}
