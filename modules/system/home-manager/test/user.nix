{ lib, system, ... }:

let
  fs = import ../../../../lib/fs.nix { inherit lib system; };
in
{
  test_readDirRecursive_1 = {
    expr = fs.readDirRecursive ./folders;
    expected = [
      ./folders/a/A
      ./folders/a/b/B
      ./folders/a/c/C
      ./folders/a/c/D
    ];
  };

  test_readDirRecursive_2 = {
    expr = fs.readDirRecursive ./folders/a/c;
    expected = [
      ./folders/a/c/C
      ./folders/a/c/D
    ];
  };
}
