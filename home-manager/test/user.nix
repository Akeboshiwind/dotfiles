{ lib, ... }:

let
  user = import ../lib/user.nix { inherit lib; system = "aarch64-darwin"; };
in {
  test_readDirRecursive_1 = {
    expr = user.readDirRecursive ./folders;
    expected = [
      ./folders/a/A
      ./folders/a/b/B
      ./folders/a/c/C
      ./folders/a/c/D
    ];
  };

  test_readDirRecursive_2 = {
    expr = user.readDirRecursive ./folders/a/c;
    expected = [
      ./folders/a/c/C
      ./folders/a/c/D
    ];
  };
}
