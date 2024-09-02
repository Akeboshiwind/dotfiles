if status is-interactive
    # Start tmux if not already running
    if command -qv tmux; and test -z "$TMUX"
        tmux attach || tmux new
    end
end

# TODO: Prompt to `fish_update_completions` occasionally

# >> Load some configs after everything else

# This is mostly to work around asdf needing to be set *after* $fish_user_paths
for config in $__fish_config_dir/conf.d.after/*
    source $config
end
