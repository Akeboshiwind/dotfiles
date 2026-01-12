# cld

Claude tmux session manager - run Claude Code in persistent tmux sessions.

Based on [cld-tmux](https://github.com/TerminalGravity/cld-tmux), rewritten in Babashka with a functional core / imperative shell architecture.

## Usage

```bash
cld                    # Start session in current directory
cld myproject          # Start for project in ~/projects/
cld myproject -n test  # Named session: claude-myproject-test
cld /path/to/dir       # Start in specific directory
cld https://github.com/user/repo  # Clone and start

cld -l                 # List sessions
cld -k session         # Kill session
cld -r old new         # Rename session
cld -s                 # Interactive picker
cld -h                 # Help
```

## Features

- Persistent sessions that survive disconnects
- Multiple named sessions per project (`-n` flag)
- GitHub URL cloning
- Session listing with activity timestamps
- Colored output

## Configuration

Set `CLD_PROJECTS_DIR` to change where projects live (default: `~/projects`).

## Development

```bash
bb test        # Run tests
bbin install . # Install locally
```

## Architecture

- `src/cld/cli.clj` - Pure argument parsing
- `src/cld/core.clj` - Pure functions (no side effects)
- `src/cld/shell.clj` - Side effects (tmux, filesystem)
- `src/cld/main.clj` - Orchestration
