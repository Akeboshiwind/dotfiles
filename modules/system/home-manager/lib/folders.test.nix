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

  # Tests for individual functions
  test_getRelativePaths = {
    expr = folders.getRelativePaths "/home/user/test" [
      "/home/user/test/file1.txt"
      "/home/user/test/dir/file2.txt"
      "/home/user/test/dir/subdir/file3.txt"
    ];
    expected = [
      "file1.txt"
      "dir/file2.txt"
      "dir/subdir/file3.txt"
    ];
  };

  test_filterPaths = {
    expr = folders.filterPaths [ "file2.txt" "dir/excluded.txt" ] [
      "file1.txt"
      "file2.txt"
      "dir/file3.txt"
      "dir/excluded.txt"
    ];
    expected = [
      "file1.txt"
      "dir/file3.txt"
    ];
  };

  test_createHomeFiles = {
    expr = folders.createHomeFiles "/source" "target/" [
      "file1.txt"
      "dir/file2.txt"
    ];
    expected = {
      "target/file1.txt" = {
        source = "/source/file1.txt";
      };
      "target/dir/file2.txt" = {
        source = "/source/dir/file2.txt";
      };
    };
  };
}
