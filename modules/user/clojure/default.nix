{ user, ... }:
{ config, pkgs, lib, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      openjdk17-bootstrap #  temurin-bin-17
      clojure
      babashka
      clj-kondo
    ];
  };

  home-manager.users."${user}" = {
    # TODO: Fix, I get permission errors for some reason
    #home.activation = {
    #  linkOpenJDK = lib.hm.dag.entryAfter ["writeBoundary"] ''
    #    run rm /Library/Java/JavaVirtualMachines/*
    #    run ln -sfv "${pkgs.openjdk17-bootstrap}" "/Library/Java/JavaVirtualMachines/"
    #  '';
    #};

    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
