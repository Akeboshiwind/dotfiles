# System Modules

System-level configuration modules.
If you want to configure things on the user level use a [user module](../user/README.md).

## Usage

Import directly in machine configurations:

```nix
imports = [
  ../modules/system/nix-darwin
];
```

## Module Structure

Standard [NixOS module](https://nixos.wiki/wiki/NixOS_modules):

```nix
{ config, pkgs, lib, ... }:
{
  # System configuration
}
```
