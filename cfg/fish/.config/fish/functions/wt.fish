function __wt_age --description 'Format a duration in seconds as a compact age: 3s, 2m, 1w'
    set -l secs $argv[1]
    test $secs -lt 0; and set secs 0

    for step in 31536000:y 2592000:mo 604800:w 86400:d 3600:h 60:m
        set -l unit (string split ':' -- $step)
        if test $secs -ge $unit[1]
            echo (math -s0 "floor($secs / $unit[1])")$unit[2]
            return
        end
    end
    echo {$secs}s
end

function __wt_list --description 'List git worktrees, most recent commit first'
    set -l now (date +%s)
    set -l paths
    set -l shas
    set -l branches

    for line in (git worktree list --porcelain)
        set -l field (string split -m1 ' ' -- $line)
        switch $field[1]
            case worktree
                set -a paths $field[2]
                set -a shas ''
                set -a branches '(detached HEAD)'
            case HEAD
                set shas[-1] $field[2]
            case branch
                set branches[-1] (string replace -r '^refs/heads/' '' -- $field[2])
            case bare
                set branches[-1] '(bare)'
        end
    end

    set -l rows
    for i in (seq (count $paths))
        set -l stamp 0
        if test -n "$shas[$i]"
            set stamp (git show -s --format=%ct $shas[$i] 2>/dev/null; or echo 0)
        end

        set -l age -
        test $stamp -gt 0; and set age (__wt_age (math $now - $stamp))

        set -a rows (string join \t \
            $stamp \
            $age \
            (path basename -- $paths[$i]) \
            (string sub -l 8 -- $shas[$i]) \
            $branches[$i] \
            (string replace -- $HOME '~' $paths[$i]))
    end

    test (count $rows) -eq 0; and return 0

    set -l ages
    set -l names
    set -l commits
    set -l refs
    set -l displays
    for row in (printf '%s\n' $rows | sort -rn -k1,1)
        set -l field (string split \t -- $row)
        set -a ages $field[2]
        set -a names $field[3]
        set -a commits $field[4]
        set -a refs $field[5]
        set -a displays $field[6]
    end

    set -l w_age (string length AGE)
    set -l w_name (string length NAME)
    set -l w_ref (string length BRANCH)
    for i in (seq (count $ages))
        set w_age (math "max($w_age, "(string length -- $ages[$i])")")
        set w_name (math "max($w_name, "(string length -- $names[$i])")")
        set w_ref (math "max($w_ref, "(string length -- $refs[$i])")")
    end

    isatty stdout; and set_color --bold
    printf '%s  %s  %s  %s  %s\n' \
        (string pad -w $w_age -- AGE) \
        (string pad -r -w $w_name -- NAME) \
        (string pad -r -w 8 -- COMMIT) \
        (string pad -r -w $w_ref -- BRANCH) \
        PATH
    isatty stdout; and set_color normal

    for i in (seq (count $ages))
        printf '%s  %s  %s  %s  %s\n' \
            (string pad -w $w_age -- $ages[$i]) \
            (string pad -r -w $w_name -- $names[$i]) \
            (string pad -r -w 8 -- $commits[$i]) \
            (string pad -r -w $w_ref -- $refs[$i]) \
            $displays[$i]
    end
end

function __wt_main_root --description 'Absolute path of the repository main worktree'
    set -l common (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); or return 1
    path dirname -- $common
end

function wt --description 'Create or switch to a git worktree'
    set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -ne 0
        echo "Not in a git repository"
        return 1
    end

    # Worktrees always hang off the main checkout, never off each other
    set -l main_root (__wt_main_root)
    set -l wt_dir "$main_root/.claude/worktrees"

    # No args: leave a worktree, otherwise list
    if test (count $argv) -eq 0
        if test (path resolve -- $git_root) != (path resolve -- $main_root)
            cd $main_root
        else
            __wt_list
        end
        return 0
    end

    set -l name $argv[1]
    set -l wt_path "$wt_dir/$name"

    # check-ignore can't classify a path outside the worktree it runs in
    if not git -C $main_root check-ignore -q "$wt_path" 2>/dev/null
        echo "Warning: .claude/worktrees is not in .gitignore"
    end

    if test -d "$wt_path"
        cd $wt_path
        return
    end

    mkdir -p "$wt_dir"
    if git show-ref --verify --quiet "refs/heads/$name"
        git worktree add --force "$wt_path" "$name"
    else
        git worktree add "$wt_path" -b "$name"
    end
    and cd $wt_path
end
