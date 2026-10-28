function wa --description 'cd to a live Claude agent\'s workspace'
    set -l rows
    for row in (claude agents --json | jq -r '.[] | [.state, .name, .cwd] | @tsv')
        # A merged worktree is deleted while its agent lives on
        test -d (string split \t -- $row)[3]; and set -a rows $row
    end

    if test (count $rows) -eq 0
        echo "No live Claude agents"
        return 1
    end

    set -l choice (printf '%s\n' $rows | fzf --delimiter \t --select-1 --exit-0 --query "$argv")
    or return
    cd (string split \t -- $choice)[3]
end
