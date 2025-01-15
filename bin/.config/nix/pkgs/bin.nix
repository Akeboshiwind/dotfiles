{ pkgs, ... }: with pkgs; [
  # TODO: Update scripts to either just use sh or babashka
  bash
  coreutils
  git
  tree
  jq
  ffmpeg
  stow
  help2man
  htop
  nmap
  imagemagick
]
