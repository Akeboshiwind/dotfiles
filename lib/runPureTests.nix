{ lib, tests, system }:
let
  results = lib.runTests tests;
in
if results == [] then 
  derivation {
    name = "tests-passed";
    builder = "/bin/sh";
    args = ["-c" "echo 'All tests passed' > $out"];
    inherit system;
  }
else 
  throw "Tests failed:\n${lib.generators.toPretty {} results}"