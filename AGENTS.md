# Dotfiles

Babashka-based dotfile manager. Installs packages and symlinks config files via a declarative manifest.

## Manifest & Actions

`manifest.edn` defines what to install:

- `bootstrap` - runs first (e.g., install mise, mas, bbin)
- `config` - list of paths to `cfg/*/base.edn` files or inline maps

Each config entry can use these actions:

- `:pkg/brew` - Homebrew packages (supports `:head true`)
- `:pkg/mise` - mise tools (`:version`, `:global`)
- `:pkg/mas` - Mac App Store apps
- `:pkg/bbin` - Babashka binaries
- `:fs/symlink` - symlink files `{"~/.target" "./source"}`
- `:fs/symlink-folder` - symlink all files in a folder
- `:osx/defaults` - macOS defaults settings

## Structure

```
├── manifest.edn        # Main manifest
├── bb.edn              # Babashka config
├── src/                # Installer code
│   ├── main.clj        # Entry point, CLI args
│   ├── manifest.clj    # Loads/parses manifest.edn
│   ├── optimise.clj    # Merges actions, expands folders, handles stale symlinks
│   ├── execute.clj     # Runs actions (brew, symlinks, etc.)
│   ├── cache.clj       # Tracks symlinks for cleanup
│   └── utils.clj       # Helpers
└── cfg/                # Dotfile configs
    └── <app>/
        ├── base.edn    # Package/symlink definitions
        └── .config/    # Actual config files to symlink
```

## Code Overview

- **main.clj** - Entry point, CLI args, orchestrates the pipeline
- **manifest.clj** - Loads and parses `manifest.edn`
- **optimise.clj** - Merges actions, expands symlink folders, handles stale symlinks
- **execute.clj** - Runs each action type (brew install, symlink, etc.)
- **cache.clj** - Tracks symlinks for cleanup

## Usage

```bash
bb -m main              # Run all actions
bb -m main :pkg/brew    # Only brew packages
bb -m main :fs/symlink  # Only symlinks
```

## Troubleshooting

### Neovim crashes when previewing files (treesitter)

Clear and reinstall treesitter parsers:

```bash
rm -rf ~/.local/share/nvim/site/parser/
nvim -c ':TSUpdate'
```
