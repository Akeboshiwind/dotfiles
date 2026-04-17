function wt --description 'Create or switch to a git worktree'
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

    # Existing worktree: just cd
    if test -d "$wt_path"
        cd "$wt_path"
        return 0
    end

    # Create new worktree
    mkdir -p "$wt_dir"
    git worktree add "$wt_path" -b "wt/$name"
    and cd "$wt_path"
end
