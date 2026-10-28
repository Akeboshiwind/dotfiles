(fn realpath [path]
  (or (vim.uv.fs_realpath path) path))

(fn list []
  "The live Claude agents, as `claude agents --json` rows with `cwd` resolved through symlinks.
  Empty when `claude agents` fails."
  (let [(ran? result) (pcall #(: (vim.system [:claude :agents :--json] {:text true}) :wait 2000))
        (parsed? rows) (if (and ran? (= 0 result.code))
                           (pcall vim.json.decode result.stdout)
                           false)]
    (if parsed?
        (icollect [_ row (ipairs rows)]
          (doto row (tset :cwd (realpath row.cwd))))
        [])))

(fn format-item [agent]
  (.. (or agent.state "") "  " agent.name "  " (vim.fn.fnamemodify agent.cwd ":~")))

(fn pick [prompt on-choice]
  "Asks for a live Claude agent and calls `on-choice` with its cwd.
  Agents whose cwd is gone, like a merged worktree, are left out."
  (vim.ui.select (icollect [_ agent (ipairs (list))]
                   (when (vim.uv.fs_stat agent.cwd) agent))
                 {: prompt :format_item format-item}
                 #(when $1 (on-choice $1.cwd))))

{: list : pick}
