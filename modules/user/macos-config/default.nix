{ user, ... }:
{ config, pkgs, ... }:

{
  # TODO: Find user specific alternative
  #       Afaik this only works for the activating user
  #       (Not actually tried it)
  # system.keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToControl = true;
  # };
  home-manager.users."${user}" = {
    targets.darwin.defaults = {
      NSGlobalDomain = {
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };
      "com.apple.Safari" = {
        IncludeDevelopMenu = true;
      };
      "com.apple.dock" = {
        autohide = true;
        tilesize = 72;
      };
      "com.apple.finder" = {
        AppleShowAllFiles = true;
      };
    };
  };
}
