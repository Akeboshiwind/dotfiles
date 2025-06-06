{ lib, fs, ... }:

rec {
  # Extract relative paths from a list of absolute paths
  getRelativePaths = source: paths:
    let
      oldPrefix = (toString source) + "/";
    in
    map (path: lib.removePrefix oldPrefix (toString path)) paths;

  # Filter paths based on exclude list
  filterPaths = exclude: paths:
    builtins.filter (path: !(builtins.elem path exclude)) paths;

  # Create home.file attribute set from relative paths
  createHomeFiles = source: target: paths:
    builtins.listToAttrs (
      map (path: {
        name = target + path;
        value = {
          source = source + ("/" + path);
        };
      }) paths
    );

  # Given a `source` path returns all files in the directory recursively
  # in the format of `home.file`.
  # `target` can be used to change the root of all the files relative to HOME (defaults to "")
  # `exclude` can be used to filter files from being returned (defaults to [])
  #
  # E.g:
  # homeFileRecursive {
  #   source = /tmp/test; # (Would be /private/tmp/test on MacOS)
  #   target = "../";
  #   exclude = ["home.nix"];
  # }
  # =>
  # {
  #   "../test.file" = { source = /tmp/test/test.file; };
  #   "../other/test.file" = { source = /tmp/test/other/test.file; };
  # }
  homeFileRecursive = {
    source,
    target ? "",
    exclude ? []
  }:
    lib.pipe source [
      fs.readDirRecursive
      (getRelativePaths source)
      (filterPaths exclude)
      (createHomeFiles source target)
    ];
}
