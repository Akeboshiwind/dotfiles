# poetry.zsh


# >> Setup path

export PATH="$HOME/.poetry/bin:$PATH"



# >> Auto-completion

mkdir -p $COMPLETION_PATH
completion_path="$COMPLETION_PATH/_poetry"
[[ -f "$completion_path" ]] || {
    info "Setting up poetry completions..."

    poetry completions zsh > $completion_path
    chmod 755 $completion_path

    info "May need to restart shell"
}
