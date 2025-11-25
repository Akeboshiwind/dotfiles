if status is-interactive
    # Start tmux if not already running
    if command -qv tmux; and test -z "$TMUX"
        tmux attach || tmux new
    end
end

# Add local bin to PATH
fish_add_path ~/.local/bin

# TODO: Prompt to `fish_update_completions` occasionally

# >> Load some configs after everything else

# I think this works but I'm not 100% sure
# Basically, asdf shims weren't being picked up (`java -version` was erroring)
# I *think* what was happening was that the shims were being added too late
# Possibly $fish_user_paths is messing up the path order?
# If so I'm not sure what I can do for that other than banning fish_set_path
# Maybe wrap it so that asdf shims are always used?
for config in $__fish_config_dir/conf.d.after/*
    source $config
end


# >> Note to future me: asdf shims broken
# tags: asdf, shim, java

# If you accidentially exit tmux completely then restart it, for some reason the asdf shims to to the back of the PATH
# This means they get overshadowed by /usr/bin.
# The solution is: Just restart Alacritty.
# Not really sure why 🤷
