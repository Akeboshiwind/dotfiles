function ct --wraps=claude --description 'Run Claude Code in a Docker sandbox'
    set -l agent_args --settings /home/agent/.claude/settings.osm.json --model opus $argv
    set -l kit_dir $HOME/dotfiles/cfg/sbx/kits
    set -l cache $HOME/.cache/sbx-templates

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
    set -l existing (sbx ls --json 2>/dev/null |
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

        echo "Your sandbox config changed after '$existing' was created."
        echo "Recreating discards its Claude history."
        read -P 'Recreate? [y/N] ' -l reply
        if test "$reply" != y
            sbx run --name $existing -- $agent_args
            return
        end
        sbx rm $existing; or return
    end

    # Stamped before the run, which lasts as long as the session: a marker written
    # on exit could postdate a template rebuild that happened during it.
    mkdir -p $cache
    touch $marker
    sbx run -t $template:latest $kit_args claude . $common -- $agent_args
end
