{ user, ... }:
{ config, pkgs, ... }:

# Apps I never expect to configure through nix
# TODO: Should this be a system module?
{
  homebrew.casks = [
    "raycast"
  ];

  homebrew.masApps = {
    "OmniFocus 4" = 1542143627;
    "Sofa" = 1276554886;
    "Timery" = 1425368544;
    "Bitwarden" = 1352778147;
    # TODO: Can I configure hooking this up to Safari?
    "Wipr 2" = 1662217862;
    # TODO: Can I configure this?
    "Tailscale" = 1475387142;
    "Fantastical" = 975937182;
    "Data Jar" = 1453273600;
    "Collections Database" = 1568395334;
    "Save to Reader" = 1640236961;
  };
}
