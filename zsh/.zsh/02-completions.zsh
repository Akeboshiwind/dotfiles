# 02-completions.zsh


# >> Basic Setup

# Expand expressions in braces which would not otherwise undergo brace explosion
setopt BRACE_CCL # Not sure if needed:

# Setup brew builtin completions
fpath=($(brew-prefix)/share/zsh/site-functions/ $fpath)

# Setup custom completions
export COMPLETION_PATH=~/.zsh/completion # Config local completion directory
mkdir -p $COMPLETION_PATH
fpath=($COMPLETION_PATH $fpath)

# Setup completions
autoload -Uz compinit
compinit -u

# Fixes error 'zsh: no matches found'
# E.g. of command that would produce error: `curl google.com/search?q=`
unsetopt nomatch



# >> Applications

# kubectl
# if [ $commands[kubectl] ]; then source <(kubectl completion zsh); fi



# >> Styling

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
