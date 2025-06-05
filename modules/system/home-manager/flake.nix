{
  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-pin.url = "github:akeboshiwind/nix-pin";

    # NOTE: If I need to get into per-system config, look into https://flake.parts
  };

  outputs =
    { nixpkgs, home-manager, nix-pin, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
      hmConfig = { username, homeDirectory ? null }:
        let
          effectiveHomeDirectory =
            if homeDirectory == null then
              "/Users/${username}"
            else
              homeDirectory;
	in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          # NOTE: To learn about the overrides convention:
          # https://nix.dev/tutorials/callpackage.html

          # Specify your home configuration modules here, for example,
          # the path to your home.nix.
          modules = [
            ./osm-files.nix
            ./osm-symlinks.nix
            ./home.nix

            # >> Shell
            #../zsh/home.nix
            ../fzf/home.nix
            ../fish/home.nix
            ../bash/home.nix
            ../tmux/home.nix

            # >> Editor
            ../nvim/home.nix
            ../vim/home.nix

            # >> Tools
            ../terraform/home.nix
            ../zoxide/home.nix
            ../ssh/home.nix
            ../git/home.nix
            ../gpg/home.nix
            ../bin/home.nix
            ../aws/home.nix
            ../llm/home.nix

            # >> Apps
            ../alacritty/home.nix

            # >> Language
            ../clojure/home.nix
            #../rust/home.nix
            #../python/home.nix
            #../golang/home.nix
          ];

          extraSpecialArgs = {
            userLib = (import ./lib/user.nix { inherit lib system; });
            inherit username;
            homeDirectory = effectiveHomeDirectory;
            inherit system;
            inherit nix-pin;
          };
        };
    in
    {
      homeConfigurations."osm" = (hmConfig { username = "osm"; });
      homeConfigurations."personal" = (hmConfig { username = "personal"; });
      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
