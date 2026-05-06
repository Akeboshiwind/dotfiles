function wt --description 'Create or switch to a git worktree'
    if set -q WT_NAME
        echo "Already in worktree '$WT_NAME'. Type 'exit' to leave first."
        return 1
    end

    set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -ne 0
        echo "Not in a git repository"
        return 1
    end

    set -l wt_dir "$git_root/.claude/worktrees"

    # No args: list worktrees
    if test (count $argv) -eq 0
        git worktree list
        return 0
    end

    set -l name $argv[1]
    set -l wt_path "$wt_dir/$name"

    # Check .gitignore
    if not git check-ignore -q "$wt_path" 2>/dev/null
        echo "Warning: .claude/worktrees is not in .gitignore"
    end

    # Existing worktree: enter subshell
    if test -d "$wt_path"
        set -lx WT_NAME $name
        fish -C "cd '$wt_path'"
        return
    end

    # Create new worktree, then enter subshell
    mkdir -p "$wt_dir"
    git worktree add "$wt_path" -b "wt/$name"
    and set -lx WT_NAME $name
    and fish -C "cd '$wt_path'"
end
