{ config, pkgs, ... }: 

let
  user = "personal";
  withUser = import ../lib/withUser.nix;
in {
  imports = withUser user [
    ../profiles/base.nix
    ../profiles/base-macos.nix
    ../profiles/dev.nix
    ../profiles/fun.nix
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
