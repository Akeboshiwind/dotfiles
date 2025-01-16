{ config, pkgs, ... }:

{
  home.file = {
    ".ssh" = {
      source = ./.ssh;
      recursive = true;
    };
  };
}
