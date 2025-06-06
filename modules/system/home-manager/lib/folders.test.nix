{ lib, system, ... }:

let
  fs = import ../../../../lib/fs.nix { inherit lib system; };
  folders = import ./folders.nix { inherit lib fs; };
in
{
  test_homeFileRecursive_allFiles = {
    expr = folders.homeFileRecursive {
      source = ../test/folders;
    };
    expected = {
      "a/A" = {
        source = ../test/folders/a/A;
      };
      "a/b/B" = {
        source = ../test/folders/a/b/B;
      };
      "a/c/C" = {
        source = ../test/folders/a/c/C;
      };
      "a/c/D" = {
        source = ../test/folders/a/c/D;
      };
    };
  };

  test_homeFileRecursive_allFiles_changeTarget = {
    expr = folders.homeFileRecursive {
      source = ../test/folders;
      target = "../";
    };
    expected = {
      "../a/A" = {
        source = ../test/folders/a/A;
      };
      "../a/b/B" = {
        source = ../test/folders/a/b/B;
      };
      "../a/c/C" = {
        source = ../test/folders/a/c/C;
      };
      "../a/c/D" = {
        source = ../test/folders/a/c/D;
      };
    };
  };

  test_homeFileRecursive_excludeFile = {
    expr = folders.homeFileRecursive {
      source = ../test/folders;
      exclude = [ "a/b/B" ];
    };
    expected = {
      "a/A" = {
        source = ../test/folders/a/A;
      };
      "a/c/C" = {
        source = ../test/folders/a/c/C;
      };
      "a/c/D" = {
        source = ../test/folders/a/c/D;
      };
    };
  };
}
