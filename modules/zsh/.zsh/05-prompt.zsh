# 05-prompt.zsh


# >> Configuration

COLOR_ROOT="%F{red}"
COLOR_USER="%F{cyan}"
COLOR_NORMAL="%F{white}"
COLOR_OK="%F{green}"
COLOR_FAIL="%F{red}"

SYMBOL_ROOT="#"
SYMBOL_USER="$"



# >> Settings

# Allow functions in the prompt
setopt PROMPT_SUBST



# >> Return code

local return_code="%(?..%{%F{red}%}%? ↵%{%f%})"



# >> Detect root

if [ ! "$(id -u)" = "0" ]; then
    USER_COLOR="${COLOR_USER}"
    USER_SYMBOL="${SYMBOL_USER}"
else
    USER_COLOR="${COLOR_ROOT}"
    USER_SYMBOL="${SYMBOL_ROOT}"
fi



# >> Current dir

local current_dir="%{%B%F{blue}%}%~%{%f%b%} "



# >> Git

ICO_DIRTY="*"

ICO_AHEAD="↑"

ICO_BEHIND="↓"

ICO_DIVERGED="↕"

git_prompt() {

    prefix="%B${COLOR_OK}"
    suffix='%f%b'

    if [ ! "$(git rev-parse --is-inside-work-tree 2> /dev/null)" ]; then
        return
    fi

    ref=$(git branch --list -a | sed -nE 's/^\* (.*)/\1/p')
    dirty="" && [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && dirty=$ICO_DIRTY
    stat=$(git status 2> /dev/null | sed -n 2p)

    case "$stat" in
        *ahead*)    stat=$ICO_AHEAD
                    ;;
        *behind*)   stat=$ICO_BEHIND
                    ;;
        *diverged*) stat=$ICO_DIVERGED
                    ;;
        *)          stat=""
                    ;;
    esac

    echo -n "%F{yellow}git:(%f"
    echo -n "$prefix"
    echo -n "${ref}${dirty}${stat}"
    echo -n "$suffix"
    echo -n "%F{yellow})%f "
}

local git_branch='$(git_prompt)%{%f%}'



# >> AWS

# Accepts a time delta in seconds and creates a pretty string output
pretty_delta() {
    delta=$1
    days="$(($delta/(60*60*24)))"

    delta="$(($delta - $days*60*60*24))"
    hours="$(($delta/(60*60)))"

    delta="$(($delta - $hours*60*60))"
    minutes="$(($delta/60))"

    seconds="$(($delta - $minutes*60))"

    delta_str=""
    if [ "$days" -gt "0" ]; then
        # We always want to display smaller times so put a space
        delta_str="${days}d "
    fi

    if [ "$days" -gt "0" ] || [ "$hours" -gt "0" ]; then
        delta_str="$delta_str${hours}h "
    fi

    if [ "$days" -gt "0" ] || [ "$hours" -gt "0" ] || [ "$minutes" -gt "0" ]; then
        delta_str="$delta_str${minutes}m "
    fi

    delta_str="$delta_str${seconds}s"

    echo "$delta_str"
}

aws_prompt() {

    prefix="%B${COLOR_OK}"
    suffix='%f%b'

    # TODO: Some way of detecting wrong account?
    if [[ -n "$AWS_PROFILE" && `pwd` =~ '/env/' && ! `pwd` =~ "/env/$AWS_PROFILE" ]]; then
        prefix="%B${COLOR_FAIL}"
        suffix='!%f%b'
    fi

    profile="$AWS_PROFILE"
    if [ -z "$profile" ]; then
        profile="$AWS_VAULT"
    fi

    if [ ! -z "$profile" ]; then

        delta_str=""
        if [ ! -z "$AWS_CREDENTIAL_EXPIRATION" ]; then
            # NOTE: Limitation in expecting 'Z' timezone
            end_time="$(TZ=Z date -j -f "%Y-%m-%dT%H:%M:%SZ" "$AWS_CREDENTIAL_EXPIRATION" +%s)"
            delta="$(($end_time - $(date +%s)))"
            if [ "$delta" -gt "0" ]; then
                delta_str="$(pretty_delta $delta)"
            else
                delta_str="%B%F{red}✘%f%b"
            fi

            delta_str=" - $delta_str"
        fi

        echo -n "%F{yellow}aws:(%f"
        echo -n "$prefix"
        echo -n "$profile$delta_str"
        echo -n "$suffix"
        echo -n "%F{yellow})%f "
    fi
}

local aws_profile='$(aws_prompt)'



# >> Terraform

tf_prompt() {

    prefix="%B${COLOR_OK}"
    suffix='%f%b'

    command -v terraform >/dev/null && {
        workspace="$(terraform workspace show)"
        [ $workspace != "default" ] && {
            echo -n "%F{yellow}tf:(%f"
            echo -n "$prefix"
            echo -n "$workspace"
            echo -n "$suffix"
            echo -n "%F{yellow})%f "
        }
    }
}

local tf_profile='$(tf_prompt)'



# >> Kubernetes

#. ~/.zsh/prompt/kube-ps1.sh
#
#KUBE_PS1_SYMBOL_ENABLE=false
#KUBE_PS1_PREFIX=
#KUBE_PS1_SUFFIX=
#local kube_prompt='$(kube_ps1)'


# >> Prompt

PROMPT="
${USER_COLOR}╭─ ${COLOR_NORMAL}${current_dir}${aws_profile}${tf_profile}${git_branch}${USER_COLOR}
╰─%B${USER_SYMBOL}%b ${COLOR_NORMAL}"
RPS1="%B${return_code}%b"
