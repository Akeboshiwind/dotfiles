{ lib, system, ... }:

let
  fs = import ./fs.nix { inherit lib system; };
  testDir = ../modules/system/home-manager/test/folders;
in
{
  test_readDirRecursive_1 = {
    expr = fs.readDirRecursive testDir;
    expected = [
      (testDir + "/a/A")
      (testDir + "/a/b/B") 
      (testDir + "/a/c/C")
      (testDir + "/a/c/D")
    ];
  };

  test_readDirRecursive_2 = {
    expr = fs.readDirRecursive (testDir + "/a/c");
    expected = [
      (testDir + "/a/c/C")
      (testDir + "/a/c/D")
    ];
  };
}