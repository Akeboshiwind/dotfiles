# Dotfiles

Babashka-based dotfile manager. Installs packages and symlinks config files via a declarative manifest.

## Philosophy

- A folder for each application
- Loose coupling between applications
- Be declarative
- Use the application's native config files
- Split config into multiple files where possible
- Comment liberally
- Use application defaults most of the time

## Setup

1. Create macOS account and sign into Mac App Store (so [mas](https://github.com/mas-cli/mas) works)
2. Clone this repo to `~/dotfiles`
3. Install prerequisites: [Homebrew](https://brew.sh), then `brew install borkdude/brew/babashka git-crypt`
4. Unlock secrets: `git-crypt unlock` (requires GPG key)
5. Run `~/dotfiles/cfg/bin/bin/bootstrap`

## Usage

```bash
bootstrap              # Run all actions
bootstrap :pkg/brew    # Only brew packages
bootstrap :fs/symlink  # Only symlinks
bootstrap --dry-run    # Preview without executing
```

## Structure

```
├── manifest.edn        # Main manifest
├── secrets.edn         # Encrypted secrets (git-crypt)
├── bb.edn              # Babashka config
├── src/                # Installer code
└── cfg/                # Dotfile configs
    └── <app>/
        ├── base.edn    # Package/symlink definitions
        └── .config/    # Actual config files to symlink
```

## Manifest

`manifest.edn` has a `:plan` key containing entries to process:

```clojure
{:plan [:ghostty                           ; keyword -> cfg/ghostty/base.edn
        "cfg/custom/config.edn"            ; string -> explicit path
        {:pkg/brew {:ripgrep {}}}]}        ; map -> inline actions
```

## Actions

### Package Managers

| Action | Description | Options |
|--------|-------------|---------|
| `:pkg/brew` | Homebrew packages | `:head`, `:cask` |
| `:pkg/mise` | mise version manager | `:version` (required), `:global` |
| `:pkg/mas` | Mac App Store | `{app-name app-id}` |
| `:pkg/bbin` | Babashka binaries | `:url`, `:local`, `:as`, `:git/tag`, `:git/sha`, `:main-opts` |
| `:pkg/npm` | npm global packages | - |
| `:pkg/script` | Run shell scripts | `:path` or `:src` |

```clojure
{:pkg/brew {:ripgrep {}
            :neovim {:head true}
            :rectangle {:cask true}}
 :pkg/mise {:node {:version "22" :global true}}
 :pkg/mas {"Tailscale" 1475387142}
 :pkg/bbin {:neil {:url "https://github.com/babashka/neil"}}}
```

### Filesystem

| Action | Description |
|--------|-------------|
| `:fs/symlink` | Symlink individual files |
| `:fs/symlink-folder` | Symlink all files in a folder recursively |

```clojure
{:fs/symlink {"~/.gitconfig" "./gitconfig"}
 :fs/symlink-folder {"~/.config/nvim" "./.config/nvim"}}
```

### macOS

| Action | Description | Options |
|--------|-------------|---------|
| `:osx/defaults` | macOS defaults | `:domain`, `:settings` or `:key`/`:value` |
| `:brew/service` | Homebrew services | `:restart`, `:sudo` |

```clojure
{:osx/defaults {:dock {:domain "com.apple.dock"
                       :settings {:autohide true
                                  :tilesize 48}}}
 :brew/service {:postgresql {:restart true}}}
```

### Claude Code

| Action | Description | Options |
|--------|-------------|---------|
| `:claude/marketplace` | Add plugin marketplaces | `:source` |
| `:claude/plugin` | Install plugins | - |
| `:claude/mcp` | Add MCP servers | `:command`, `:args`, `:env`, `:scope` |

```clojure
{:claude/marketplace {:my-marketplace {:source "user/repo"}}
 :claude/plugin {:some-plugin {}}
 :claude/mcp {:my-server {:command "npx"
                          :args ["-y" "some-mcp-server"]
                          :env {:API_KEY #secret :my-api-key}}}}
```

## Dependencies

Actions can declare dependencies using `:dep/provides` and `:dep/requires`:

```clojure
;; In bootstrap: mise installation provides :pkg/mise capability
{:pkg/brew {:mise {:dep/provides #{:pkg/mise}}}}

;; Later: node installation requires mise to be installed first
{:pkg/mise {:node {:version "22"
                   :dep/requires #{:pkg/mise}}}}

;; Depend on a specific action (not just capability)
{:claude/mcp {:my-server {:dep/requires #{[:pkg/brew :claude-code]
                                          [:pkg/mise :node]}}}}
```

Actions are executed in topological order based on dependencies.

## Secrets

Sensitive values live in `secrets.edn` (encrypted with [git-crypt](https://github.com/AGWA/git-crypt)):

```clojure
;; secrets.edn
{:github-token "ghp_xxx"
 :api-key "sk-xxx"}
```

Reference secrets in config with the `#secret` reader tag:

```clojure
{:claude/mcp {:server {:env {:API_KEY #secret :api-key}}}}
```

To disable a secret without removing it:

```clojure
{:api-key :secret/disabled}
```

## Tools

The `tools/` directory contains local Babashka tools installed via bbin:

| Tool | Description |
|------|-------------|
| `hello` | Template/example tool |

Tools are installed with `:local` in manifest.edn:

```clojure
{:pkg/bbin {:hello {:local "./tools/hello"}}}
```

### Creating a new tool

1. Copy `tools/hello` to `tools/mytool`
2. Rename namespace in `src/hello/main.clj` to `mytool.main`
3. Update `bb.edn` with the new main namespace
4. Add to manifest: `{:pkg/bbin {:mytool {:local "./tools/mytool"}}}`
5. Run `bootstrap :pkg/bbin`

## Updating after config change

```bash
bootstrap
```
