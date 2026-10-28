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

(fn open-float []
  (let [width (math.floor (* vim.o.columns 0.9))
        height (math.floor (* vim.o.lines 0.8))]
    (vim.api.nvim_open_win (vim.api.nvim_create_buf false true) true
                           {:relative :editor :style :minimal :border :rounded
                            : width : height
                            :row (math.floor (/ (- vim.o.lines height) 2))
                            :col (math.floor (/ (- vim.o.columns width) 2))})))

(fn pick [prompt on-choice]
  "Asks for a Claude agent, or the repository it works in, as fish's `ga` does,
  and calls `on-choice` with the chosen directory."
  (let [win (open-float)
        chosen (vim.fn.tempname)
        fzf (.. "agent-rows " (vim.api.nvim_win_get_width win)
                " | fzf --ansi --delimiter '\t' --with-nth 2 --no-sort --layout reverse"
                " --select-1 --exit-0 --prompt " (vim.fn.shellescape (.. prompt "> "))
                " > " (vim.fn.shellescape chosen))]
    (vim.fn.jobstart [:sh :-c fzf]
                     {:term true
                      :on_exit (fn [_ code]
                                 (vim.api.nvim_win_close win true)
                                 (case code
                                   0 (on-choice (-> (vim.fn.readfile chosen) (. 1) (vim.split "\t") (. 1)))
                                   ;; fzf --exit-0 on an empty list
                                   1 (vim.notify "No Claude agents" vim.log.levels.WARN))
                                 (vim.fn.delete chosen))})
    (vim.cmd.startinsert)))

{: list : pick}
