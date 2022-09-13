# Dotfiles

My personal dotfiles repo

The main philosiphy is **simplicity**, in particular I've decided this means:
- Separate application config from other configs
    - In this repo each application has it's own folder
    - This makes it easy to configure an application
    - Although the cost is it's harder to see how applications depend on eachother
    - Some exceptions can be made, for example `python` contains config for both
      poetry and pyenv because if I want one I'll want both
- Applications should only loosely depend on eachother
    - Where possible account for the fact that an application might not be present
    - This isn't always possible:
        - Some applications don't supporting it
        - There's not always a sane alternative
        - My own laziness
- Don't generate config indirectly
    - Use the standard config files where possible
    - This means no nix (dispite how cool it is)
        - If you want to customise it you have to learn:
            - That function's parameters
            - And probably still that application's config too
        - If the application changes it's config then you have to relearn
          everything to change it
        - That's too complicated
- Split config into multiple files where possible
    - This is to separate concerns
    - See `ssh` for an example
    - For ssh in particular it allows me to have `home` and `work`
      configurations in separate repos
- Comment your configs
    - Sections for configs are especially nice
    - Remember that when you read the config in a years time you won't remember
      why you needed that weird setting enabled
- Use the application defaults
    - This helps with when you go to other machines
    - Not super critical (probably something I should focus less on?)
    - One clear exception would be for config location
        - Try and keep most things in `.config` if you can

Key Features
- Managed by [stow](https://www.gnu.org/software/stow/)
- Applications to be installed are specified in a file:
    - `<app name>/.config/mpm/pkgs/<package manager>/<app name>`
    - One day I'll actually finish `mpm` and get this working...

## Install instructions

1. Install `stow`
2. Clone this repo to your home directory
3. Install whatever configs you want using `stow <folder-name>`.
   Some applications, particularly on linux, require config in other directories, read the config readme for info.

## Bootstrap

TODO: Have a bootstrap scrit to setup stuff how I like it
TODO: Finish `mpm` so keeping track of packages is easier
