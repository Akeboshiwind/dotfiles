# 06-aliases.zsh


# >> General

alias mkdir="mkdir -p"
alias fuck='sudo $(fc -ln -1)'



# >> Git

alias g="git"
alias ga="git add"
alias gc="git commit -m"
alias gs="git status"
alias gd="git diff"
alias gps="git push"
alias gpl="git pull"



# >> Terraform

alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"


# >> Kubernetes

alias k="kubectl"

alias h="helm"
alias ht="helm --tiller-namespace turing"

