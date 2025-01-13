# Nix packages

Instead of using brew, use nix to install packages.



## Initial setup

```console
$ cd ~/nix-pkgs
$ nix profile install --impure .
```

(`--impure` is needed because the flake needs to look at path outside it's directory: `~/.config/nix/pkgs`)


## Syncing changes with files

```console
$ nix profile upgrade --impure --all
```


## Show 

```console
$ nix eval .#packages.aarch64-darwin.default
```
