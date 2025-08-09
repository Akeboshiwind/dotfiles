;; .config/nvim/init.fnl
;; TODO: Add explanations


;; >> Package Manager

;; Map before loading lazy.nvim
(set vim.g.mapleader ",")

(local lazypath (.. (vim.fn.stdpath "data") "/lazy"))

(fn ensure [user repo branch]
  (let [install-path (.. lazypath "/" repo)
        branch (or branch "main")]
    (if (not (vim.loop.fs_stat install-path))
      (vim.fn.system
        ["git"
         "clone"
         "--filter=blob:none"
         (.. "https://github.com/" user "/" repo ".git")
         (.. "--branch=" branch)
         install-path])
     (vim.opt.rtp:prepend install-path))))

(ensure :folke :lazy.nvim :stable)
(ensure :Olical :nfnl)

(local lazy (require "lazy"))
(local {: map : filter : update} (require :nfnl.core))
(local cfg (require :util.cfg))

(let [path "plugins"
      configs (->> (cfg.find-modules path true)
                   (map require)
                   cfg.flatten-1
                   (map cfg.ensure-table))
      G (cfg.group-by-key configs)
      plugins (->> configs
                   (filter cfg.plugin? configs)
                   (map #(update $ :config #(cfg.wrap-config $ G))))]
  (lazy.setup plugins
              {:dev {:path "~/prog/prog/nvim/"}
               :ui {:border :single
                    :icons {:cmd "⌘"
                            :config "🛠"
                            :event "📅"
                            :ft "📂"
                            :init "⚙"
                            :keys "🗝"
                            :plugin "🔌"
                            :runtime "💻"
                            :source "📄"
                            :start "🚀"
                            :task "📌"}}
               :checker {:enabled true
                         :check_pinned true}
               :performance {:rtp {:disabled_plugins ["gzip"
                                                      "matchit"
                                                      "matchparen"
                                                      "netrwPlugin"
                                                      "tarPlugin"
                                                      "tohtml"
                                                      "tutor"
                                                      "zipPlugin"]}}})
  (let [colorscheme (cfg.only G.colorscheme)]
    (vim.cmd (.. "colorscheme " colorscheme))))



;; >> Utils

(fn _G.P [...]
  (print (vim.inspect ...)))

(vim.api.nvim_create_user_command :Nohl :nohl {})

(vim.api.nvim_create_user_command
  :Tab
  (fn [opts]
    (let [width (tonumber opts.args)]
      (set vim.bo.tabstop width)
      (set vim.bo.shiftwidth width) 
      (set vim.bo.softtabstop width)))
  {:nargs 1
   :desc "Set tab width for current buffer"})



;; >> Usability

(set vim.opt.ignorecase true) ; In searches, ignore the case
(set vim.opt.smartcase true) ; Unless there's an uppercase letter
(set vim.opt.splitright true) ; Make splits to the right
(set vim.opt.inccommand "nosplit") ; Show live replacements with the :s command
(set vim.opt.updatetime 1000) ; Make the CursorHold event trigger after 1 second not 4



;; >> Indentation

; Enable filetype specific .vim files to be loaded)
(vim.cmd "filetype plugin indent on")

(set vim.opt.tabstop 4) ; Show existing tab with 4 spaces width
(set vim.opt.shiftwidth 4) ; When indenting with '>', use 4 spaces width
(set vim.opt.expandtab true) ; On pressing tab, insert 4 spaces



;; >> Filetype conversions

(vim.filetype.add
  {:extension {:mdx :markdown}
   :filename {:Jenkinsfile :groovy}})



;; >> Setup Diagnostic Signs

; Always enable sign column
(set vim.opt.signcolumn "yes")

; Link SignColumn & LignNr highlights
; TODO: Maybe move this to theme specific config?
(vim.cmd "highlight! link SignColumn LineNr")

(let [s vim.diagnostic.severity]
  (vim.diagnostic.config
    {:signs {:text {s.ERROR ""
                    s.WARN ""
                    s.INFO ""
                    s.HINT ""}}}))



;; >> Setup Term Colors

(if (not= 0 (vim.fn.exists "+termguicolors"))
    ; Tell nvim that terminal supports truecolor
    ; If not set then the theme doesn't work
    ; You can test using the truecolor-test script in bin or at:
    ; https://gist.github.com/XVilka/8346728
    (set vim.opt.termguicolors true))



;; >> Setup spell checking

;; Basic usage:
;;  ]s - move to next misspelled word
;;  z= - see suggestions
;;  zg - add word to spellfile
;; See `:help spell` for more
;; TODO: Add custom spellfile for all words < 3 characters

(set vim.opt.spelllang "en_gb")
(set vim.opt.spell true)
(set vim.opt.spelloptions "camel") ; Include camel case words
(set vim.opt.spellcapcheck "") ; Disable capitalization check

nil
