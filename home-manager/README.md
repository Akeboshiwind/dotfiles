# Home Manager

Used to install packages & manage config files.



## Prerequisites

See [here](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone) for more up to date information.

1. Make sure both `nix-command` and `flakes` are enabled in nix
2. Run: `nix run home-manager/master -- init --switch ~/dotfiles/home-manager`


## Updating after config change

```sh
home-manager --flake ~/dotfiles/home-manager switch
```


## Testing

Home manager allows you to just run the build step:

```sh
home-manager --flake ~/dotfiles/home-manager build
```

This produces a `./result` symlink you can inspect:

```sh
# See what will be put in the home directory
tree -la result/home-files
```
