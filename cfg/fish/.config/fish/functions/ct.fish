function ct --wraps=claude --description 'Run Claude Code in a Docker sandbox'
    set -l agent_args --settings /home/agent/.claude/settings.osm.json --model opus $argv

    # sbx rejects --kit when re-attaching, so the kits are creation-only. A
    # sandbox is keyed on its primary workspace, which is what ct passes as ".".
    set -l existing (sbx ls --json 2>/dev/null |
        jq -r --arg w (pwd) '.sandboxes[] | select(.workspaces[0] == $w) | .name' | head -n1)
    if test -n "$existing"
        sbx run --name $existing -- $agent_args
        return
    end

    # Kits carry what a sandbox never inherits from the host: CLAUDE.md and
    # plugins, git identity, GitHub egress. git-ssh-sign is upstream's, pinned;
    # its source must be in kit.allowedSources (see cfg/sbx/manifest.edn).
    set -l kits \
        --kit $HOME/.config/sbx/kits/osm-claude \
        --kit $HOME/.config/sbx/kits/osm-git \
        --kit $HOME/.config/sbx/kits/osm-github \
        --kit "git+https://github.com/docker/sbx-kits-contrib.git#ref=v0.14.0&dir=git-ssh-sign"

    # The Clojure toolchain downloads three binaries and a JDK's worth of deps,
    # so it is limited to the trees that actually need it.
    set -l dir (pwd)
    for root in $HOME/dotfiles $HOME/prog/work/xtdb/xtdb
        if test "$dir" = "$root"; or string match -q -- "$root/*" "$dir"
            set -a kits --kit $HOME/.config/sbx/kits/osm-clojure
            break
        end
    end

    # A linked worktree's .git is a pointer into the main checkout's
    # .git/worktrees/<name>. Mount that directory too or the sandbox cannot
    # resolve the pointer and the agent gets no git at all.
    set -l common
    set -l info (git rev-parse --path-format=absolute --git-dir --git-common-dir 2>/dev/null)
    if test (count $info) -eq 2; and test $info[1] != $info[2]
        set common $info[2]
    end

    sbx run $kits claude . $common -- $agent_args
end
