{ pkgs, system, ... }:

let
  inherit (pkgs) lib;
  
  # We need to mock fs.readDirRecursive because homeFileRecursive creates
  # attribute names from file paths. When using real Nix store paths, these
  # attribute names would contain store path contexts, which Nix doesn't allow.
  # This is a limitation of testing functions that create attrsets with dynamic
  # names from store paths.
  mockFs = {
    readDirRecursive = path: [
      "${path}/a/A"
      "${path}/a/b/B"
      "${path}/a/c/C"
      "${path}/a/c/D"
    ];
  };
  
  folders = import ./folders.nix { inherit lib; fs = mockFs; };
in
{
  test_homeFileRecursive_allFiles = {
    expr = folders.homeFileRecursive {
      source = "/test";
    };
    expected = {
      "a/A" = {
        source = "/test/a/A";
      };
      "a/b/B" = {
        source = "/test/a/b/B";
      };
      "a/c/C" = {
        source = "/test/a/c/C";
      };
      "a/c/D" = {
        source = "/test/a/c/D";
      };
    };
  };

  test_homeFileRecursive_allFiles_changeTarget = {
    expr = folders.homeFileRecursive {
      source = "/test";
      target = "../";
    };
    expected = {
      "../a/A" = {
        source = "/test/a/A";
      };
      "../a/b/B" = {
        source = "/test/a/b/B";
      };
      "../a/c/C" = {
        source = "/test/a/c/C";
      };
      "../a/c/D" = {
        source = "/test/a/c/D";
      };
    };
  };

  test_homeFileRecursive_excludeFile = {
    expr = folders.homeFileRecursive {
      source = "/test";
      exclude = [ "a/b/B" ];
    };
    expected = {
      "a/A" = {
        source = "/test/a/A";
      };
      "a/c/C" = {
        source = "/test/a/c/C";
      };
      "a/c/D" = {
        source = "/test/a/c/D";
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
