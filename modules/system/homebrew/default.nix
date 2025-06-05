{ config, lib, ... }:

{
  homebrew = {
    enable = true;
    user = "personal";
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    brews = [
      "mas" # To enable homebrew.masApps
    ];
  };
}