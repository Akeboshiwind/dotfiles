{ user, ... }:
{ ... }: {
  # Desktop-specific tools for macOS

  imports = [
    # >> Terminal setup
    (import ../modules/alacritty { inherit user; })
  ];
}
