;; Drives real Neovim children with this checkout's config, each with a UI
;; attached so startup runs as it does in a terminal.
;; Run a test file with: nvim --clean -l test/<name>_test.lua

(local config-dir (-> (. arg 0) vim.fs.abspath vim.fs.dirname vim.fs.dirname))

(fn tempdir []
  (let [dir (vim.fn.tempname)]
    (vim.fn.mkdir dir :p)
    dir))

(local root (tempdir))
(local xdg-config (.. root "/config"))
(vim.fn.mkdir xdg-config :p)
(vim.uv.fs_symlink config-dir (.. xdg-config "/nvim"))

(local env {:XDG_CONFIG_HOME xdg-config
            :XDG_STATE_HOME (.. root "/state")})

(local children [])

(fn spawn [args cwd]
  (let [chan (vim.fn.jobstart args {:rpc true :cwd cwd :env env})]
    (table.insert children chan)
    chan))

(fn wait-until [pred ?ms]
  (vim.wait (or ?ms 15000) pred 50))

(fn exec-lua [chan code ...]
  (vim.rpcrequest chan :nvim_exec_lua code [...]))

(fn start [cwd ?args]
  (let [chan (spawn (vim.list_extend [:nvim :--embed] (or ?args [])) cwd)]
    (vim.rpcrequest chan :nvim_ui_attach 80 24 {})
    (wait-until #(= 1 (exec-lua chan "return vim.v.vim_did_enter")))
    chan))

(fn start-headless [cwd]
  (spawn [:nvim :--headless :--embed] cwd))

(fn stop [chan]
  "Quit `chan` the way a user would, so VimLeavePre runs.
  An embedded child with a file open never terminates after VimLeave,
  so it reports VimLeave back to us and we close it."
  (let [left (.. "harness_left_" chan)]
    (exec-lua chan "local name = ...
                    vim.api.nvim_create_autocmd('VimLeave', {callback = function()
                      vim.rpcnotify(1, 'nvim_set_var', name, true) end})" left)
    (vim.rpcnotify chan :nvim_command "qa!")
    (when (not (wait-until #(or (. vim.g left) (= 0 (. (vim.fn.jobwait [chan] 0) 1))) 10000))
      (error "child never reached VimLeave" 0))
    (vim.fn.jobstop chan)
    (vim.fn.jobwait [chan] 5000)))

(fn buffer-names [chan]
  (exec-lua chan "return vim.tbl_map(vim.api.nvim_buf_get_name, vim.api.nvim_list_bufs())"))

(fn buffer-filetypes [chan]
  (exec-lua chan "return vim.tbl_map(function(b) return vim.bo[b].filetype end, vim.api.nvim_list_bufs())"))

(fn current [chan]
  (exec-lua chan "return {name = vim.api.nvim_buf_get_name(0), filetype = vim.bo.filetype}"))

(fn press [chan keys]
  (vim.rpcrequest chan :nvim_input keys))

(fn start-fake-lsp [chan]
  "Attaches an in-process LSP client named `fake` to the current buffer."
  (exec-lua chan "
    vim.lsp.start({name = 'fake', cmd = function(dispatchers)
      local closing = false
      local function exit()
        if not closing then closing = true dispatchers.on_exit(0, 0) end
      end
      return {
        request = function(method, _, callback)
          callback(nil, method == 'initialize' and {capabilities = {}} or nil)
          return true, 1
        end,
        notify = function(method) if method == 'exit' then exit() end return true end,
        is_closing = function() return closing end,
        terminate = exit,
      }
    end})"))

(fn lsp-client-names [chan]
  (exec-lua chan "return vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients())"))

(fn session-saved? [chan]
  (= 1 (exec-lua chan "return vim.fn.filereadable(require('persistence').current())")))

(fn project [files]
  (let [dir (tempdir)]
    (each [_ file (ipairs files)]
      (vim.fn.writefile [file] (.. dir "/" file)))
    dir))

(fn ends-with? [s suffix]
  (vim.endswith (or s "") suffix))

(fn has-buffer? [names suffix]
  (: (vim.iter names) :any #(ends-with? $1 suffix)))

(fn check [ok? message]
  (when (not ok?) (error message 0)))

(fn run [tests]
  (var failed 0)
  (each [_ [name f] (ipairs tests)]
    (let [t0 (vim.uv.hrtime)
          (ok? err) (pcall f)
          ms (math.floor (/ (- (vim.uv.hrtime) t0) 1e6))]
      (if ok?
          (print (.. "PASS  " name "  (" ms "ms)"))
          (do (set failed (+ failed 1))
              (print (.. "FAIL  " name "\n      " (tostring err)))))))
  (each [_ chan (ipairs children)] (vim.fn.jobstop chan))
  (vim.fn.delete root :rf)
  (os.exit (if (= failed 0) 0 1)))

{: wait-until : exec-lua : start : start-headless : stop : buffer-names : buffer-filetypes : current
 : press : start-fake-lsp : lsp-client-names : session-saved?
 : project : ends-with? : has-buffer? : check : run}
