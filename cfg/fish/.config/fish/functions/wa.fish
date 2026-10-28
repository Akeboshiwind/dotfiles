function wa --description 'cd to a Claude agent\'s workspace, or to its repository'
    set -l agents (claude agents --json --all | string collect)
    set -l running (claude agents --json | jq -c 'map(.id)')

    set -l live
    for dir in (printf '%s' $agents | jq -r '.[].cwd')
        # A merged worktree is deleted while its agent lives on
        test -d $dir; and set -a live $dir
    end

    if test (count $live) -eq 0
        echo "No Claude agents"
        return 1
    end

    # Summaries and update times live only in each job's state file
    set -l jobs '{}'
    set -l states ~/.claude/jobs/*/state.json
    set -q states[1]
    and set jobs (jq -s 'map(select(.daemonShort) | {key: .daemonShort, value: {detail, updatedAt}}) | from_entries' $states | string collect)

    set -l program (path dirname -- (functions --details wa))/wa.jq
    set -l choice (printf '%s' $agents \
        | jq -r --arg home $HOME --argjson jobs $jobs --argjson running $running --argjson cols $COLUMNS -f $program --args $live \
        | fzf --ansi --delimiter \t --with-nth 2 --no-sort --layout reverse \
            --select-1 --exit-0 --query "$argv")
    or return
    cd (string split \t -- $choice)[1]
end
