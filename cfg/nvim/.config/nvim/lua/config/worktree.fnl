(local session (require :config.session))

(fn realpath [path]
  (or (vim.uv.fs_realpath path) path))

(fn live-agents []
  (let [(ran? result) (pcall #(: (vim.system [:claude :agents :--json] {:text true}) :wait 2000))
        (parsed? rows) (if (and ran? (= 0 result.code))
                           (pcall vim.json.decode result.stdout)
                           false)]
    (if parsed?
        (collect [_ row (ipairs rows)]
          (values (realpath row.cwd) row.name))
        {})))

(fn read-info [dir]
  (let [(ran? result) (pcall #(: (vim.system [:git :rev-parse :--path-format=absolute
                                              :--show-toplevel :--git-dir :--git-common-dir]
                                             {:text true :cwd dir})
                                 :wait))]
    (if (and ran? (= 0 result.code))
        (let [[top git-dir common-dir] (vim.split result.stdout "\n" {:trimempty true})]
          {:name (vim.fs.basename top) :linked? (not= git-dir common-dir) :repo common-dir})
        false)))

;; Keyed by cwd, whose worktree never changes, so entries are never invalidated.
;; `false` records "not a repository", so the statusline doesn't run git on every redraw there.
(local infos {})

;; getcwd() is "" once the cwd is deleted.
(var last-cwd "")

(fn info []
  "The worktree the cwd is in, as {:name :linked? :repo}, or nil outside a git repository.
  `repo` is the repository's common git directory, which outlives a deleted worktree."
  (let [cwd (case (vim.fn.getcwd)
              "" last-cwd
              dir (do (set last-cwd dir) dir))]
    (when (= nil (. infos cwd))
      (tset infos cwd (read-info cwd)))
    (or (. infos cwd) nil)))

(fn parse-worktree [block]
  (let [item {}]
    (each [_ line (ipairs (vim.split block "\n"))]
      (let [(key value) (line:match "^(%S+)%s?(.*)$")]
        (case key
          :worktree (set item.path (realpath value))
          :branch (set item.branch (pick-values 1 (value:gsub "^refs/heads/" "")))
          :detached (set item.branch "(detached)")
          :prunable (set item.prunable true))))
    item))

(fn list [?agents]
  "The worktrees of the cwd's repository, main checkout first, without prunable ones.
  Each is {:path :name :branch :agent :current?}.
  `?agents` maps worktree paths to agent names; it defaults to the running Claude agents."
  (let [agents (or ?agents (live-agents))
        cwd (realpath (vim.fn.getcwd))
        repo (?. (info) :repo)
        result (when repo
                 (: (vim.system [:git :worktree :list :--porcelain] {:text true :cwd repo}) :wait))]
    (if (or (= nil result) (not= 0 result.code))
        []
        (icollect [_ block (ipairs (vim.split result.stdout "\n\n" {:trimempty true}))]
          (let [item (parse-worktree block)]
            (when (not item.prunable)
              (doto item
                (tset :name (vim.fs.basename item.path))
                (tset :agent (. agents item.path))
                (tset :current? (= item.path cwd)))))))))

(fn format-item [item]
  (.. (if item.current? "* " "  ")
      item.name
      (if item.branch (.. "  [" item.branch "]") "")
      (if item.agent (.. "  " item.agent) "")))

(fn pick [prompt on-choice]
  "Asks for a worktree of the cwd's repository and calls `on-choice` with its path."
  (vim.ui.select (list) {: prompt :format_item format-item}
                 #(when $1 (on-choice $1.path))))

(fn switch [dir]
  "Moves the whole editor to the worktree at `dir`: saves this session, closes everything,
  then restores `dir`'s session if it has one.
  Fires `User WorktreeSwitched` with {:from :to} as data.
  Refuses, changing nothing, while a file buffer has unsaved changes."
  (let [from (realpath (vim.fn.getcwd))
        to (realpath dir)]
    (when (and (not= from to) (session.clearable?))
      (session.save)
      (session.clear)
      (vim.cmd.cd (vim.fn.fnameescape to))
      ((. (require :persistence) :load))
      (vim.api.nvim_exec_autocmds :User {:pattern :WorktreeSwitched
                                         :data {: from : to}}))))

(fn find-files [dir]
  (LazyVim.pick.open :files {:cwd dir}))

{: list : pick : switch : find-files : info}
