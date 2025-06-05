{ config, pkgs, ... }: let
  user = "personal";
in {
  imports = [
    (import ../profiles/base.nix { inherit user; })
    (import ../profiles/base-macos.nix { inherit user; })
    (import ../profiles/dev.nix { inherit user; })
    (import ../profiles/fun.nix { inherit user; })
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
    nixpkgs.config.allowUnfree = true;
  };
}
