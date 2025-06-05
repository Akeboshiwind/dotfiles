# 01-environment.zsh


# >> Manpath

export MANPATH=":"



# >> Path
# (Maybe remove once settled in with nix?)

export PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$HOME/bin

# dotnet
export PATH=$PATH:/usr/local/share/dotnet:~/dotnet/tools

# go
export PATH=$PATH:~/go/bin:~/bin

# kakfa
export PATH=$PATH:~/kafka/kafka_2.11-2.1.0/bin



# >> Editor

export EDITOR=vim
export VISUAL=vim
