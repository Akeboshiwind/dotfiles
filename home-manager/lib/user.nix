{ lib, ... }:

rec {
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
