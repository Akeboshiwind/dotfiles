;; lazy.fnl

;; >> Ensure minimum required plugins are installed
(local lazypath (.. (vim.fn.stdpath "data") "/lazy"))

(local newline "\n") ; \

(fn ensure [user repo branch]
  (let [install-path (.. lazypath "/" repo)
        branch (or branch "main")
        uv (or vim.uv vim.loop)]
    (when (not (uv.fs_stat install-path))
      (let [out (vim.fn.system
                  ["git"
                   "clone"
                   "--filter=blob:none"
                   (.. "https://github.com/" user "/" repo ".git")
                   (.. "--branch=" branch)
                   install-path])]
        (when (not= (vim.v.shell_error) 0)
          (vim.api.nvim_echo
            [[(.. "Failed to clone " repo newline) :ErrorMsg]
             [out :WarningMsg]
             [(.. newline "Press any key to exit...")]])
          (vim.fn.getchar)
          (os.exit 1))))
    (vim.opt.rtp:prepend install-path)))

(ensure :folke :lazy.nvim :stable)
(ensure :Olical :nfnl)



;; >> Setup LazyVim

(let [lazy (require :lazy)]
  (lazy.setup
    {:spec [{1 :LazyVim/LazyVim :import "lazyvim.plugins"}
            {:import "plugins"}]
     :defaults {:lazy false
                :version false}
     :install {:colorscheme [:alabaster :kanagawa]}
     :checker {:enabled true
               :notify false}
     :performance {:rtp
                   {:disabled_plugins
                    [:gzip
                     :tarPlugin
                     :tohtml
                     :tutor
                     :zipPlugin]}}}))
