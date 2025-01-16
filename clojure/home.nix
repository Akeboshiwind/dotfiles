{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    openjdk17-bootstrap #  temurin-bin-17
    clojure
    babashka
    clj-kondo
  ];

  home.file = {
    ".clojure".source = ./.clojure;
    ".shadow-cljs".source = ./.shadow-cljs;
  };
}
