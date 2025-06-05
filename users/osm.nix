{ config, pkgs, ... }: {
  users.users.osm = {
    name = "osm";
    home = "/Users/osm";
  };

  home-manager.users.osm = {
    home = {
      stateVersion = "24.11";
    };

    programs.home-manager.enable = true;
    nixpkgs.config.allowUnfree = true;
  };
}
