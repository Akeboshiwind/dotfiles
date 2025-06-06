{ pkgs, system, ... }:

let
  inherit (pkgs) lib;
  fs = import ./fs.nix { inherit lib system; };
  
  # Create test directory structure in the Nix store
  testDir = pkgs.runCommand "fs-test-folders" {} ''
    mkdir -p $out/a/b $out/a/c
    touch $out/a/A $out/a/b/B $out/a/c/C $out/a/c/D
  '';
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