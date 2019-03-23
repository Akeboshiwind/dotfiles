# .zshrc
# Format and lots of config taken and reconfigured from:
# https://github.com/xero/dotfiles


# >> Load configs

for config in $(ls ~/.zsh/*.zsh | sort -V); . $config
