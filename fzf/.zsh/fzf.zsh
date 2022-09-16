# fzf.zsh


# >> Setup fzf

if [[ ! "$PATH" == *"$(brew-prefix fzf)/bin"* ]]; then
    export PATH="${PATH:+${PATH}:}$(brew-prefix fzf)/bin"
fi



# >> Auto-completion

# TODO:
# The problem is that this overrides all completions :think:
#source "$(brew-prefix fzf)/shell/completion.zsh" 2> /dev/null

# Allow the Auto-completion to work with empty inputs
FZF_COMPLETION_TRIGGER=""



# >> Custom completions

# If you're wanting to do this, probably looking into stealing this code:
# https://doronbehar.com/articles/ZSH-FZF-completion/





# >> Key bindings

source "$(brew-prefix fzf)/shell/key-bindings.zsh"

# Add support for vim-like page up and down
export FZF_DEFAULT_OPTS="--bind ctrl-u:page-up,ctrl-d:page-down"
