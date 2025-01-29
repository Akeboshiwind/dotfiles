{ lib, system, ... }:

rec {
  # Adapted from: https://lazamar.co.uk/nix-versions
  # Use the above to find the right rev
  withRevision = (
    {
      pkg,
      rev,
      url ? "https://github.com/NixOS/nixpkgs/",
      ref ? "refs/heads/nixpkgs-unstable",
    }:
    let
      versionPkgs =
        import
          (builtins.fetchGit {
            name = "${pkg}-from-${rev}";
            url = url;
            ref = ref;
            rev = rev;
          })
          {
            inherit system;
          };
    in
    versionPkgs.${pkg}
  );

  # Returns the contents of the directory `path`, recursively searching
  # subdirectories as a list of paths.
  # Does not search symlinks.
  readDirRecursive = (
    path:
    lib.pipe path [
      builtins.readDir
      builtins.attrNames
      # Take a file name & make it a full path
      (builtins.map (file: path + ("/" + file)))
      (lib.foldl (
        acc: filePath:
        if
          (lib.pathIsDirectory filePath)
        # Recur if path is a directory
        then
          acc ++ (readDirRecursive filePath)
        # Otherwise return up the stack
        else
          acc ++ [ filePath ]
      ) [ ])
    ]
  );
}
