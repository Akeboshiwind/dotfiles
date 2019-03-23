# Dotfiles

A dotfile repo managed by [stow](https://www.gnu.org/software/stow/)

## Install instructions

1. Install stow
2. Clone this repo
3. Install whatever configs you want using `stow <folder-name>`

### Bare Essentials:

`stow -v bin zsh gpg tmux gitssh vim`

### Useful Stuff:

`stow -v spacemacs docker`

### OSX Specific

`stow -v iterm2`

## Bootstrap

In the `bin` package there is a `bootstrap.sh` script that installs the basics
needed to run the `update.sh` script which is also in the `bin` package.

The `update.sh` script is `indempotent` so when you want to add a new package
just add it to the appropriate section and run the script.

Currently these scripts only work with OSX.

## Tips and Tricks

Renamed some files in a package?
Use `stow -R <package-name>`

Installing `linux-print`?
That needs to be installed using `stow linux-print -t /`

## TODO

- Alter windows bootstrap and update scripts
