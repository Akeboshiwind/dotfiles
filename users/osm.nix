{ config, pkgs, ... }: 

let
  user = "osm";
  withUser = import ../lib/withUser.nix;
in {
  imports = withUser user [
    ../profiles/base.nix
    ../profiles/base-macos.nix
    ../profiles/dev.nix
  ];

  users.users."${user}" = {
    name = user;
    home = "/Users/${user}";
  };

  home-manager.users."${user}" = {
    home = {
      stateVersion = "24.11";
    };

    programs.home-manager.enable = true;
  };
}
