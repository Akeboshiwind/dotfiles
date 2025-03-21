# .bashrc


# >> Bash mode detection

# If not running interactively, don't do anything
[[ $- != *i* ]] && return



# >> History

export HISTCONTROL=ignoreboth

shopt -s histappend

export HISTSIZE=
export HISTFILESIZE=
export HISTFILE=~/.bash_eternal_history

export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"



# >> Window

shopt -s checkwinsize



# >> Less

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"



# >> Colours

# Import coloursceme from 'wal' asynchromousely
#(cat ~/.cache/wal/sequences &)

case "$(uname -s)" in
    Darwin)
	    ;;
    *)
        if [ -x /usr/bin/dircolors ]; then
	    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	    alias ls='ls --color=auto'
	    alias grep='grep --color=auto'
		alias fgrep='fgrep --color=auto'
		alias egrep='egrep --color=auto'
	    fi ;;
esac



# >> Prompt

case "$(uname -s)" in
    Darwin)
	    ;;
    *)
	PS1='\u@\h:\w\$ '
	;;
esac

case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;\u@\h: \w\a\]$PS1"
        ;;
    *)
        ;;
esac




# >> Aliases

for filename in ~/.bash_aliases/*; do
    . $filename
done



# >> Completion


case "$(uname -s)" in
    Darwin)
        [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
    ;;
    *)
	if ! shopt -oq posix; then
	  if [ -f /usr/share/bash-completion/bash_completion ]; then
	    . /usr/share/bash-completion/bash_completion
	  elif [ -f /etc/bash_completion ]; then
	    . /etc/bash_completion
	  fi
	fi
	;;
esac



# >> GPG

export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent



# >> Bash options

set -o vi



# >> Path

PATH="$PATH:~/bin/"



# >> Sourcing

if [ -d ~/bin/sources ]; then
    for f in ~/bin/sources/*; do
        source $f;
    done
fi
