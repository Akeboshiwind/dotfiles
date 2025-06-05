{
  config,
  lib,
  fs,
  ...
}:

let
  homeFileRecursive = (import ./lib/folders.nix { inherit lib fs; }).homeFileRecursive;

  # A path that is also a directory (for validation)
  directoryPath = lib.mkOptionType {
    name = "directory path";
    check = v: (builtins.isPath v) && (lib.pathIsDirectory v);
    merge = lib.mergeEqualOption;
  };
in
{
  options = {
    custom.home.folders = lib.mkOption {
      description = "List of directories whose contents will be recursively linked into the home directory.";
      default = [ ];
      type =
        with lib.types;
        listOf (submodule {
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
              default = [ ];
              example = [ "home.nix" ];
              type = listOf str;
            };
          };
        });
    };
  };

  config = {
    home.file = lib.pipe config.custom.home.folders [
      # Take each config & map to the `home.file` format
      (builtins.map homeFileRecursive)
      # Merge all configs together for `home.file`
      (lib.foldl lib.recursiveUpdate { })
    ];
  };
}
