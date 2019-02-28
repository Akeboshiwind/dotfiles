# bash alias file

# >> ls

alias ls='ls -Ash --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l=ls
alias sl=ls



# >> tree

alias tree='tree -C' # Enable colours by default



# >> alert

alias alert='notify-send --urgency=low \
                 -i "$([ $? = 0 ] && \
                       echo terminal || \
                       echo error)" \
                 "$(history| \
                    tail -n1| \
                    sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'



# >> less

alias less='less -r' # Enable colours by default
