# User Modules

User-specific application configurations.
These are ordinary system-level modules that can configure anything, but are designed to be user-specific.

## Usage

Import via `withUser` helper in profiles:

```nix
imports = withUser user [
  ../modules/user/git
  ../modules/user/tmux
];
```

The same as:
```nix
imports = [
  (imports ../modules/user/git { inherit user; })
  (imports ../modules/user/tmux { inherit user; })
];
```

## Module Structure

Each module takes a user parameter then follows the [NixOS module](https://nixos.wiki/wiki/NixOS_modules) structure:

```nix
{ user, ... }:
{ config, pkgs, ... }:
{
  # System packages for this user
  users.users."${user}".packages = with pkgs; [ ... ];
  
  # User-specific configuration
  home-manager.users."${user}" = {
    # config here
  };
}
```
