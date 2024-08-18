if status is-interactive
    # Start tmux if not already running
    if command -qv tmux; and test -z "$TMUX"
        tmux attach || tmux new
    end
end

# Disable greeting
set fish_greeting ""

# TODO: Prompt to `fish_update_completions` occasionally
