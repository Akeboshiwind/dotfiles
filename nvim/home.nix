{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim

    # For parinfer-rust in Clojure config
    rustup

    # For fuzzy searching
    ripgrep

    # For installing LSPs with nvim-lsp-installer
    nodejs
    wget
    ninja # Lua
    luajitPackages.luarocks # fennel_ls etc.
  ];

  osm.home.folders = [
    { source = ./.; exclude = ["home.nix" ".config/nvim/lazy-lock.json"]; }
  ];

  osm.home.dotfileSymlinks.".config/nvim/lazy-lock.json" = "nvim/.config/nvim/lazy-lock.json";
}
