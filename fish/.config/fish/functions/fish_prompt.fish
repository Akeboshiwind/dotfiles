function fish_prompt --description 'Write out the prompt'
    set -l last_status $status
    set -l normal (set_color normal)
    set -l yellow (set_color yellow)
    set -l status_color (set_color green)
    set -l cwd_color (set_color $fish_color_cwd)
    set -l git_color (set_color brpurple)

    # >> PWD
    # Since we display the prompt on a new line allow the directory names to be longer.
    set -q fish_prompt_pwd_dir_length
    or set -lx fish_prompt_pwd_dir_length 0
    set -l pwd "$cwd_color$(prompt_pwd)$normal"

    # >> Git Status
    set -lx __fish_git_prompt_showdirtystate true
    set -lx __fish_git_prompt_showupstream informative
    set -lx __fish_git_prompt_showcolorhints true
    set -lx __fish_git_prompt_color green
    set -lx __fish_git_prompt_color_prefix yellow
    set -lx __fish_git_prompt_color_suffix yellow
    set -l git_status "$(fish_git_prompt '(%s)')"
    if test -n $git_status
        set git_status "$(string trim $git_status)"
        set git_status $yellow"git:$git_color$git_status$normal"
    end

    # >> Prompt Status
    set -l prompt_status ""
    # Color the prompt in red on error
    if test $last_status -ne 0
        set status_color (set_color $fish_color_error)
        set prompt_status $status_color "[" $last_status "]" $normal
    end

    # >> Prompt Prefix
    set -l prefix '❯'
    # Color the prompt differently when we're root
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set cwd_color (set_color $fish_color_cwd_root)
        end
        set prefix '#'
    end

    echo
    echo -s $pwd ' ' $git_status ' ' $prompt_status
    echo -n -s $status_color $prefix ' ' $normal
end
