{ lib, fs, ... }:

{
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
  homeFileRecursive = (
    {
      source,
      target ? "",
      exclude ? [ ],
    }:
    let
      # For calculating target paths
      newPrefix = target;
      oldPrefix = ((toString source) + "/");
    in
    (lib.pipe source [
      fs.readDirRecursive
      # Calculate target paths
      # They should either be relative to `source`, later they are altered by `target
      (builtins.map (
        path:
        (lib.pipe path [
          toString
          (lib.removePrefix oldPrefix)
        ])
      ))
      # Remove files in the `exclude` list
      # TODO: Make fancier, allow regex matching etc
      (builtins.filter (target: !(builtins.elem target exclude)))
      # Map into the `home.file` format
      (builtins.map (target: {
        name = (newPrefix + target);
        value = {
          source = source + ("/" + target);
        };
      }))
      builtins.listToAttrs
    ])
  );
}
