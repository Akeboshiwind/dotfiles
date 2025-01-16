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

  home.file = {
    ".config/nvim".source = ./.config/nvim;
  };
}
