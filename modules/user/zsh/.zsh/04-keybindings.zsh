# 04-keybindings.zsh


# >> Set vim mode keybinds

bindkey -v



# >> Configure vim mode

# Reduce delay on escape
export KEYTIMEOUT=1

# Set the cursor based on the mode
function zle-line-init zle-keymap-select () {
    case $KEYMAP in
        vimcmd) echo -ne "\e[2 q"
                ;;
        *)      echo -ne "\e[6 q"
    esac
}
zle -N zle-line-init
zle -N zle-keymap-select



# >> Common vim keybinds

bindkey '^P' up-history
bindkey '^N' down-history

# Fix backspace and ^h not woring after returning from command mode
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

# Fix ctrl-w to work like normal
bindkey '^w' backward-kill-word

# Rebind ctrl-r for searching history
bindkey '^r' history-incremental-search-backward

# Make shift-Tab go up in the selection menu
bindkey '^[[Z' reverse-menu-complete
