# >> Terraform


# >> Aliases

alias tf="terraform"



# >> Completions

# Only install the completions if terraform is installed
command -v terraform 1>/dev/null && {
    autoload -U +X bashcompinit
    bashcompinit

    complete -o nospace -C $(which terraform) terraform
}

