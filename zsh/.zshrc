# .zshrc


# >> Load configs

for config in $(ls ~/.zsh/*.zsh | sort -V); . $config
