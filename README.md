# Dotfiles

My personal dotfiles repo

The main philosiphy is **simplicity**, in particular I've decided this means:
- Separate application config from other configs
    - In this repo each application has it's own folder
    - This makes it easy to configure an application
    - Although the cost is it's harder to see how applications depend on eachother
- Applications should only loosely depend on eachother
    - Where possible account for the fact that an application might not be present
    - This isn't always possible:
        - Some applications don't supporting it
        - There's not always a sane alternative
        - Laziness
- Don't generate config indirectly
    - Use the standard config files where possible
    - This means no nix (dispite how cool it is)
        - Here you have a functions which generate config
        - If you want to customise it you have to:
            - Learn that functions parameters (and not the application's config)
            - Probably learn that application's config too
        - If the application changes it's config then you have to relearn
          everything to change it
        - That's too complicated
- Split config into multiple files where possible
    - See `ssh` for an example
    - For ssh in particular it allows me to have `home` and `work`
      configurations in separate repos
- Comment your configs
    - Sections for configs are especially nice
    - Remember that when you read the config in a years time you won't remember
      why you needed that weird setting enabled
- Use the application defaults
    - This helps with when you go to other machines
    - Not super critical

Key Features
- Managed by [stow](https://www.gnu.org/software/stow/)
- Applications to be installed are specified in a file:
    - `<app name>/.config/mpm/pkgs/<package manager>/<app name>`
    - I have a script (soonTM to be a full application) which makes sure I only
      have packages on that list installed

TODO: Update below

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
