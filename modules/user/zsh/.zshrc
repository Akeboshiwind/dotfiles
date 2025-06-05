# .zshrc
# Format and lots of config taken and reconfigured from:
# https://github.com/xero/dotfiles


# >> Tmux

[ -z "$TMUX" ] && { tmux attach || tmux new }


# >> Config variables

export COMPLETION_PATH=~/.zsh/completion



# >> Utils
# Log functions stolen from kiss linux <3

# Setup colors for kiss logging
glcol='\033[1;33m' lcol2='\033[1;34m' lclr='\033[m'

# $ log 'My epic log'
# -> My epic log
# $ log secion_name 'My epic log'
# -> section_name My epic log
# $ log secion_name 'My epic log' override
# override section_name My epic log
log() {
    printf '%b%s %b%s%b %s\n' \
        "$lcol" "${3:-->}" "${lclr}${2:+$lcol2}" "$1" "$lclr" "$2" >&2
}

war() {
    log "$1" "$2" "${3:-WARNING}"
}

info() {
    log "$1" "$2" "${3:-INFO}"
}

# >> Load configs

for config in $(ls ~/.zsh/*.zsh | sort -V); . $config
