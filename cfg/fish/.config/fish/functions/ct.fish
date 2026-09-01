function ct --wraps=claude --description 'Run Claude Code in a Docker sandbox'
    set -l agent_args --settings /home/agent/.claude/settings.osm.json --model opus $argv
    set -l kit_dir $HOME/dotfiles/cfg/sbx/kits
    set -l cache $HOME/.cache/sbx-templates

    _ct_palette
    set -e _ct_opened

    # --show-toplevel names a worktree, not the repository it belongs to. The
    # common dir points into the main checkout, so its parent is the repository
    # root — and it is the directory that has to be mounted anyway.
    set -l info (git rev-parse --path-format=absolute \
                     --show-toplevel --git-dir --git-common-dir 2>/dev/null)
    set -l root (pwd)
    set -l common
    if test (count $info) -eq 3
        set root $info[1]
        # Only a linked worktree has a git dir distinct from the common dir; a
        # submodule's two differ in location but still agree.
        if test $info[2] != $info[3]
            set root (path dirname -- $info[3])
            # Mount it, or the sandbox cannot resolve the pointer in the
            # worktree's .git file and the agent gets no git at all.
            set common $info[3]
        end
    end

    # Convention over configuration: a kit named after the repository directory is
    # that repository's kit, and syn builds a template of the same name from
    # osm-base plus it. Adding a project means adding a kit and a manifest entry,
    # not editing this.
    set -l repo (path basename -- $root)
    set -l template osm-base
    set -l kits $kit_dir/osm-base
    if test -d $kit_dir/$repo
        set template $repo
        set -a kits $kit_dir/$repo
    end

    # The repository paths, not ~/.config/sbx/kits: the same paths syn builds the
    # templates from, and `find` below would report a symlink rather than walk it.
    set -l kit_args
    for kit in $kits
        set -a kit_args --kit $kit
    end
    # Signing resolves the key from the forwarded agent at signing time, so it is
    # in no template and has to be applied at every create. Its source must be in
    # kit.allowedSources — see cfg/sbx/manifest.edn.
    set -a kit_args --kit "git+https://github.com/docker/sbx-kits-contrib.git#ref=v0.14.0&dir=git-ssh-sign"

    # sbx rejects --kit and -t when re-attaching, so both are creation-only. A
    # sandbox is keyed on its primary workspace, which is what ct passes as ".".
    # No daemon and no sbx both read as "no existing sandbox", so the lookup's
    # own errors are dropped and the create below reports the problem in full.
    set -l existing (_ct_wait --quiet "Looking for a sandbox on this workspace" sbx ls --json |
        jq -r --arg w (pwd) '.sandboxes[] | select(.workspaces[0] == $w) | .name' | head -n1)

    # Keyed on the workspace, like the sandbox itself, so it survives a rename.
    set -l marker $cache/ws(string replace -a / - (pwd))

    if test -n "$existing"
        # Whole kit trees, not just spec.yaml: files/ is copied from the kit at
        # every create, so an edit to CLAUDE.md needs no new template but does
        # need a new sandbox. No marker means the sandbox predates templates.
        set -l changed (find $kits -newer $marker -print -quit 2>/dev/null)
        if test -e $marker; and test (count $changed) -eq 0
            sbx run --name $existing -- $agent_args
            return
        end

        _ct_say "Your sandbox config changed after '$_ct_bold$existing$_ct_off' was created."
        _ct_say "Recreating discards its Claude history."
        if not _ct_ask "Recreate?"
            sbx run --name $existing -- $agent_args
            return
        end

        # Only its confirmation is dropped — a failure still arrives on stderr.
        _ct_wait "Removing '$existing'" sbx rm --force $existing >/dev/null; or return
        _ct_say "Removed '$_ct_bold$existing$_ct_off'."
    end

    # Stamped before the run, which lasts as long as the session: a marker written
    # on exit could postdate a template rebuild that happened during it.
    mkdir -p $cache
    touch $marker
    _ct_say "Creating a sandbox from template '$_ct_bold$template$_ct_off'."
    sbx run -t $template:latest $kit_args claude . $common -- $agent_args
end

# Every field stays set, empty away from a terminal: fish drops a whole
# concatenation when any part of it is an unset list, taking the message with it.
function _ct_palette --description 'Set the gutter palette for this ct invocation'
    set -g _ct_bold ''
    set -g _ct_dim ''
    set -g _ct_off ''
    set -g _ct_badge ' ct '
    set -g _ct_gutter '▌'
    if isatty stderr
        set -g _ct_bold (set_color -o)
        set -g _ct_dim (set_color brblack)
        set -g _ct_off (set_color normal)
        set -g _ct_badge (set_color -o black -b yellow)" ct "(set_color normal)
        set -g _ct_gutter (set_color yellow)"▌"(set_color normal)
    end
end

# Lazy, so a ct that has nothing to say stays silent, and the badge still lands
# above the first line of whatever it does say.
function _ct_open --description 'Print the ct badge, once per ct invocation'
    if set -q _ct_opened
        return
    end
    set -g _ct_opened
    printf '%s\n' "$_ct_badge" >&2
end

function _ct_say --description 'Write one line of ct chatter down the gutter'
    _ct_open
    printf '%s %s\n' "$_ct_gutter" (string join ' ' -- $argv) >&2
end

function _ct_ask --description 'Ask on the gutter; true only on an explicit y'
    _ct_open
    read -P "$_ct_gutter $_ct_bold$argv[1]$_ct_off [y/N] " -l reply
    test "$reply" = y
end

# Stdout passes through untouched, so a caller can capture it; stderr comes back
# down the gutter, and --quiet drops it instead for a lookup whose failure is
# already a meaningful answer. Stdin is closed: a command that prompts would
# write it to the held-back stderr and then wait, invisibly, forever.
function _ct_wait --description 'Run a command behind a spinner, replaying its output once it finishes'
    argparse --stop-nonopt quiet -- $argv; or return 2
    set -l message $argv[1]
    set -l cmd $argv[2..-1]

    if not isatty stderr
        if set -q _flag_quiet
            $cmd </dev/null 2>/dev/null
        else
            $cmd </dev/null
        end
        return $status
    end

    # An external process, because `&` on a fish function or begin block runs it
    # in the foreground whenever job control is off, which is every shell that is
    # not interactive.
    fish --no-config --command '
        # A command that returns promptly is never drawn over at all.
        sleep 0.3
        set -l frames ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
        set -l i 1
        # Bounded: an interrupt kills ct without unwinding it, and an unbounded
        # spinner would then spin for the life of the terminal.
        for tick in (seq 4000)
            printf "\r\e[2K%s %s%s%s %s…" $argv[1] $argv[2] $frames[$i] $argv[3] $argv[4] >&2
            set i (math "$i % "(count $frames)" + 1")
            sleep 0.08
        end' "$_ct_gutter" "$_ct_dim" "$_ct_off" "$message" &
    set -l spinner $last_pid

    # Held back rather than interleaved: the command writes to the one line the
    # spinner is redrawing.
    set -l scratch (mktemp -d -t ct.XXXXXX)
    $cmd </dev/null >$scratch/out 2>$scratch/err
    set -l code $status

    kill $spinner 2>/dev/null
    printf '\r\e[2K' >&2
    if not set -q _flag_quiet
        while read -l line
            _ct_say $line
        end <$scratch/err
    end
    cat $scratch/out
    rm -rf $scratch
    return $code
end
