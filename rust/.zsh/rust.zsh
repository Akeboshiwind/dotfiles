# >> Rust completions


# >> Config

cargo_completion_path=$COMPLETION_PATH/_cargo
rustup_completion_path=$COMPLETION_PATH/_rustup



# >> PATH

PATH="$HOME/.cargo/bin:$PATH"



# >> Completions

# Only install the completions if rustup is installed
command -v rustup 1>/dev/null && {
    installed_completions=false

    # >> Rustup

    [ -e "$rustup_completion_path" ] || {
        info "Installing Rustup completions..."
        rustup completions zsh rustup > $rustup_completion_path
        info "Installed!"
        installed_completions=true
    }



    # >> Cargo

    [ -e "$cargo_completion_path" ] || {
        info "Installing Cargo completions..."
        rustup completions zsh cargo > $cargo_completion_path
        info "Installed!"
        installed_completions=true
    }

    [ $installed_completions = 'true' ] && {
        war "Installed rust completions, restart shell to see them working"
    }
}

