# 01-environment.zsh


# >> Path

export PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/local/share/dotnet:~/dotnet/tools:~/bin:$PATH



# >> Editor

export EDITOR=vim
export VISUAL=vim



#>> GPG

export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
