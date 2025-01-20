{ config, lib, userLib, ... }:

let
  homeFileRecursive = (import ./lib/folders.nix { inherit lib userLib; }).homeFileRecursive;

  # A path that is also a directory (for validation)
  directoryPath = lib.mkOptionType {
    name = "directory path";
    check = v: (builtins.isPath v) && (lib.pathIsDirectory v);
    merge = lib.mergeEqualOption;
  };
in {
  options = {
    osm.home.folders = lib.mkOption {
      description = "Attribute set of folders to link into the user home.";
      default = [];
      type = with lib.types; listOf (submodule {
        options = {
          source = lib.mkOption {
            description = "The path of the directory.";
            type = directoryPath;
          };
          target = lib.mkOption {
            description = "Path to target directory relative to HOME.";
            default = "";
            example = "../";
            type = str;
          };
          exclude = lib.mkOption {
            description = "List of files to exclude from output.";
            default = [];
            example = ["home.nix"];
            type = listOf str;
          };
        };
      });
    };
  };

  config = {
    home.file = lib.pipe config.osm.home.folders [
      # Take each config & map to the `home.file` format
      (builtins.map homeFileRecursive)
      # Merge all configs together for `home.file`
      (lib.foldl lib.recursiveUpdate {})
    ];
  };
}
