# Home Manager

Used to install packages & manage config files.



## Setup

See [here](https://nix-community.github.io/home-manager/index.xhtml#sec-flakes-standalone) for more up to date information.

1. Make sure both `nix-command` and `flakes` are enabled in nix (Try out [Determinate Systems Installer](https://determinate.systems/nix-installer/)?)
2. Run: `nix run home-manager/master -- init --switch ~/dotfiles/home-manager`

> [!TIP]
> ### Enable `nix-command` and `flakes`
> Add a file `~/.config/nix/nix.conf` with the following contents:
> ```
> experimental-features = nix-command flakes
> ```

> [!IMPORTANT]
> ### Multiple accounts
> Make sure to use the multi-user installation for Nix.
>
> If the `nix` command doesn't work on your second account you can add the following snippet to `/etc/zshrc`:
> ```zsh
> # Nix
> if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
>   . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
> fi
> # End Nix
> ```
>
> You may also need to add your new user to the `nixbld` group:
> ```sh
> sudo dseditgroup -o edit -a <username> -t user nixbld
> ```
>
> The following may be required (not sure, it was part of my debugging process)
> <details><summary>Copy store encryption key</summary>
>
> Nix stores the `Nix Store` encryption key in the [MacOS keychain](https://github.com/DeterminateSystems/nix-installer/blob/ff27099895e9a3ca55e440eb1599c754fa999655/src/action/macos/encrypt_apfs_volume.rs#L205).
>
> To use the same store with multiple users you'll need to export this key to your other users.
>
> Here's a quick script to export the existing key:
> ```sh
> service="$(security find-generic-password -a "Nix Store" | awk -F'"' '/"svce"/ {print $4}')"
> password="$(security find-generic-password -a "Nix Store" -w)"
>
> echo "To import the Nix Store encryption password into the keychain, run the following command in your terminal:"
>
> echo "security add-generic-password \
> -a 'Nix Store' \
> -s '$service' \
> -l 'Nix Store encryption password' \
> -D 'Encrypted volume password' \
> -j 'Added automatically by the Nix installer for use by /Library/LaunchDaemons/org.nixos.darwin-store.plist' \
> -w '$password' \
> -T '/System/Library/CoreServices/APFSUserAgent' \
> -T '/System/Library/CoreServices/CSUserAgent' \
> -T '/usr/bin/security'"
> ```
>
> </details>


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
