{
  config,
  lib,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  options = {
    custom.home.liveLinks = lib.mkOption {
      description = "Attribute set of files to symlink from the live dotfiles repository (not copied to Nix store).";
      default = { };
      type =
        with lib.types;
        attrsOf str;
    };
  };

  config = {
    home.file = lib.pipe config.custom.home.liveLinks [
      (builtins.mapAttrs (_: v: { source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${v}"; }))
    ];
  };
}
