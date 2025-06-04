{ config, pkgs, ... }: {
  users.users.osm = {
    name = "osm";
    home = "/Users/osm";
  };

  home-manager.users.osm = {
    home = {
      username = "osm";
      homeDirectory = "/Users/osm";
      stateVersion = "24.11";
    };

    programs.home-manager.enable = true;
    nixpkgs.config.allowUnfree = true;
  };
}
