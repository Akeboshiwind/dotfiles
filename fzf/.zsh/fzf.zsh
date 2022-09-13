# fzf.zsh


# >> Setup fzf

if [[ ! "$PATH" == *"$(brew-prefix fzf)/bin"* ]]; then
    export PATH="${PATH:+${PATH}:}$(brew-prefix fzf)/bin"
fi



# >> Auto-completion

[[ $- == *i* ]] && source "$(brew-prefix fzf)/shell/completion.zsh" 2> /dev/null



# >> Key bindings

source "$(brew-prefix fzf)/shell/key-bindings.zsh"

# Add support for vim-like page up and down
export FZF_DEFAULT_OPTS="--bind ctrl-u:page-up,ctrl-d:page-down"
