function ga --description 'cd to a Claude agent\'s workspace, or to its repository'
    set -l choice (agent-rows $COLUMNS \
        | fzf --ansi --delimiter \t --with-nth 2 --no-sort --layout reverse \
            --select-1 --exit-0 --query "$argv")
    or return
    set -l dir (string split \t -- $choice)[1]
    # A heading without a directory, like Pinned
    test -n "$dir"; and cd $dir
end
