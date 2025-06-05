{ config, pkgs, ... }: {
  users.users.personal = {
    name = "personal";
    home = "/Users/personal";
  };

  home-manager.users.personal = {
    home = {
      stateVersion = "24.11";
    };

    programs.home-manager.enable = true;
    nixpkgs.config.allowUnfree = true;
  };
}
