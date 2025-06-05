{ user, ... }:
{ config, pkgs, nix-pin, system, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      # 1.2.9
      # https://www.nixhub.io/packages/terraform
      (nix-pin.lib.withRevision {
        inherit system;
        pkg = "terraform";
        rev = "17f716dbf88d1c224e3a62d762de4aaea375218e";
      })
    ];
  };

  home-manager.users."${user}" = {
    osm.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
