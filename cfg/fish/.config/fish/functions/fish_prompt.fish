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
        set git_status " $git_status"
    end

    # >> Detect Nix Shell
    set -l nix_status ""
    if set -q IN_NIX_SHELL
        set nix_status " "$yellow"nix:"$name
    end

    # >> Detect Worktree / Submodule
    # Only a linked worktree has a git dir distinct from the common dir; a submodule's
    # agree. --show-superproject-working-tree emits a 4th line only inside a submodule.
    set -l wt_status ""
    set -l repo (git rev-parse --path-format=absolute --show-toplevel --git-dir --git-common-dir --show-superproject-working-tree 2>/dev/null)
    if test (count $repo) -ge 3
        set -l here (path basename -- $repo[1])
        if test $repo[2] != $repo[3]
            set wt_status " "$yellow"wt:"$git_color$here$normal
        else if set -q repo[4]
            set wt_status " "$yellow"sub:"$git_color$here$normal
        end
    end

    # >> Detect AWS Profile
    set -l aws_status ""
    if set -q AWS_PROFILE
        set aws_status " "$yellow"aws:"(set_color cyan)$AWS_PROFILE$normal
    end

    # >> Prompt Status
    set -l prompt_status ""
    # Color the prompt in red on error
    if test $last_status -ne 0
        set status_color (set_color $fish_color_error)
        set prompt_status $status_color "[" $last_status "]" $normal
        set prompt_status " "$prompt_status
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
    echo -s $pwd $nix_status $wt_status $aws_status $git_status $prompt_status
    echo -n -s $status_color $prefix ' ' $normal
end
