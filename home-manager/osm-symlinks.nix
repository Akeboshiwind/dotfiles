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
    osm.home.dotfileSymlinks = lib.mkOption {
      description = "Attribute set of paths to link to the users home directory relative to the dotfiles root.";
      default = [ ];
      type =
        with lib.types;
        attrsOf str;
    };
  };

  config = {
    home.file = lib.pipe config.osm.home.dotfileSymlinks [
      (builtins.mapAttrs (_: v: { source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${v}"; }))
    ];
  };
}
