{ user, ... }:
{ config, pkgs, inputs, system, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      # 1.2.9
      # https://www.nixhub.io/packages/terraform
      (inputs.nix-pin.lib.withRevision {
        inherit system;
        pkg = "terraform";
        rev = "17f716dbf88d1c224e3a62d762de4aaea375218e";
      })
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
