# 06-aliases.zsh


# >> General

alias mkdir="mkdir -p"



# >> Git

alias g="git"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gs="git status"
alias gd="git diff"
alias gdf="git diff"
alias gps="git push"
alias gpsh="git push"
alias gpl="git pull"
alias gsm='git send-email --smtp-pass=\"$(pass show --password personal/google.com)\"'



# >> Terraform

alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"



# pass

alias pass="gopass"
