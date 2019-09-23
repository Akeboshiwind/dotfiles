# 01-environment.zsh


# >> Manpath

export MANPATH=":"



# >> Path
# (Maybe remove once settled in with nix?)

export PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$HOME/bin

# dotnet
export PATH=$PATH:/usr/local/share/dotnet:~/dotnet/tools

# go
export PATH=$PATH:~/go/bin:~/bin:$PATH



# >> Editor

export EDITOR=vim
export VISUAL=vim



#>> GPG

export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
