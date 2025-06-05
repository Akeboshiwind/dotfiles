{ lib, ... }:

let
  fs = import ../../../../lib/fs.nix {
    inherit lib;
    system = "aarch64-darwin";
  };
  folders = import ../lib/folders.nix { inherit lib fs; };
in
{
  test_homeFileRecursive_allFiles = {
    expr = folders.homeFileRecursive {
      source = ./folders;
    };
    expected = {
      "a/A" = {
        source = ./folders/a/A;
      };
      "a/b/B" = {
        source = ./folders/a/b/B;
      };
      "a/c/C" = {
        source = ./folders/a/c/C;
      };
      "a/c/D" = {
        source = ./folders/a/c/D;
      };
    };
  };

  test_homeFileRecursive_allFiles_changeTarget = {
    expr = folders.homeFileRecursive {
      source = ./folders;
      target = "../";
    };
    expected = {
      "../a/A" = {
        source = ./folders/a/A;
      };
      "../a/b/B" = {
        source = ./folders/a/b/B;
      };
      "../a/c/C" = {
        source = ./folders/a/c/C;
      };
      "../a/c/D" = {
        source = ./folders/a/c/D;
      };
    };
  };

  test_homeFileRecursive_excludeFile = {
    expr = folders.homeFileRecursive {
      source = ./folders;
      exclude = [ "a/b/B" ];
    };
    expected = {
      "a/A" = {
        source = ./folders/a/A;
      };
      "a/c/C" = {
        source = ./folders/a/c/C;
      };
      "a/c/D" = {
        source = ./folders/a/c/D;
      };
    };
  };
}
