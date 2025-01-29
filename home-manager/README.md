# Home Manager

Used to install packages & manage config files.



## Setup

See [here](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone) for more up to date information.

1. Make sure both `nix-command` and `flakes` are enabled in nix (Try out [Determinate Systems Installer](https://determinate.systems/nix-installer/)?)
2. Run: `nix run home-manager/master -- init --switch ~/dotfiles/home-manager`


## Updating after config change

```sh
home-manager --flake ~/dotfiles/home-manager switch
```


## Trying out config changes

Home manager allows you to just run the build step:

```sh
home-manager --flake ~/dotfiles/home-manager build
```

This produces a `./result` symlink you can inspect:

```sh
# See what will be put in the home directory
tree -la result/home-files
```

## Format

```sh
nix fmt .
```


## Common errors


### `error: path '<nix store path to file you imported>' does not exist

Nix flakes require files to be tracked by the git repo.
Simply stage the file and the error should be fixed.


## Running tests

TODO: Make a command in the nix flake instead. [Using checks?](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake-check.html)

```sh
./test/runTests.sh
Success!
```

## Useful links

- [home-manager manual](https://nix-community.github.io/home-manager/index.xhtml#ch-writing-modules)
- [nix builtins + nixpkgs lib documentation viewer](https://teu5us.github.io/nix-lib.html)
- [Useful nix hacks](http://www.chriswarbo.net/projects/nixos/useful_hacks.html)
