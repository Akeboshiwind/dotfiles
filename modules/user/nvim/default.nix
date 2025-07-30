{ user, ... }:
{ config, pkgs, ... }:

{
  users.users."${user}" = {
    packages = with pkgs; [
      neovim

      # For parinfer-rust in Clojure config
      cargo

      # For fuzzy searching
      ripgrep

      # For installing LSPs with nvim-lsp-installer
      nodejs
      wget
      ninja # Lua
      luajitPackages.luarocks # fennel_ls etc.
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix" ".config/nvim/lazy-lock.json"]; }
    ];

    custom.home.liveLinks.".config/nvim/lazy-lock.json" = "modules/user/nvim/.config/nvim/lazy-lock.json";
  };
}
