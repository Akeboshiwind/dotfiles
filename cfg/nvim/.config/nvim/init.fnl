;; .config/nvim/init.fnl


;; >> Global Utility Function

(fn _G.P [...] (print (vim.inspect ...)))



; <<
;; >> Leader Key

(set vim.g.mapleader ",")



; <<
;; >> Basic Settings

(set vim.opt.ignorecase true) ; In searches, ignore the case
(set vim.opt.smartcase true) ; Unless there's an uppercase letter
(set vim.opt.splitright true) ; Make splits to the right
(set vim.opt.inccommand "nosplit") ; Show live replacements with the :s command
(set vim.opt.updatetime 1000) ; Make the CursorHold event trigger after 1 second not 4
(set vim.opt.signcolumn "yes")
(set vim.opt.spell true)
(set vim.opt.spelllang "en_gb")
(set vim.opt.spelloptions "camel") ; Include camel case words
(set vim.opt.spellcapcheck "") ; Disable capitalization check



; <<
;; >> Clipboard

;; Make y/p use system clipboard
(vim.keymap.set [:n :v] :y "\"+y" {:desc "Yank to system clipboard"})
(vim.keymap.set :n      :Y "\"+Y" {:desc "Yank line to system clipboard"})
(vim.keymap.set [:n :v] :p "\"+p" {:desc "Paste from system clipboard"})
(vim.keymap.set [:n :v] :P "\"+P" {:desc "Paste before from system clipboard"})
(vim.keymap.set [:n :v] :d "\"+d" {:desc "Delete to system clipboard"})
(vim.keymap.set [:n :v] :D "\"+D" {:desc "Delete line to system clipboard"})
; NOTE: Use "0p to paste from vim yank register})



; <<
;; >> Indentation

(set vim.opt.tabstop 4) ; Show existing tab with 4 spaces width
(set vim.opt.shiftwidth 4) ; When indenting with '>', use 4 spaces width
(set vim.opt.expandtab true) ; On pressing tab, insert 4 spaces



; <<
;; >> Folds

(set vim.opt.foldcolumn "0") ; disable
(set vim.opt.foldtext "") ; show the first line syntax highlighted
(set vim.opt.foldlevelstart 99) ; don't auto-close folds
(set vim.opt.foldopen "") ; disable vim auto-opening folds (e.g. '[' and search)
(set vim.opt.foldmethod "marker") ; default fold method
(set vim.opt.foldmarker ">>,<<")



; <<
;; >> Persistence

; Only save folds and cursor position
(set vim.opt.viewoptions "folds,cursor")

;; Auto save/restore folds & cursor position
(vim.api.nvim_create_autocmd [:BufWinLeave]
  {:pattern "?*" :command "silent! mkview"})
(vim.api.nvim_create_autocmd [:BufWinEnter]
  {:pattern "?*" :command "silent! loadview"})



; <<
;; >> Colors & UI

(if (not= 0 (vim.fn.exists "+termguicolors"))
  ; Tell nvim that terminal supports truecolor
  ; If not set then the theme doesn't work
  ; You can test using the truecolor-test script in bin or at:
  ; https://gist.github.com/XVilka/8346728
  (set vim.opt.termguicolors true))

(vim.cmd "highlight! link SignColumn LineNr")



; <<
;; >> Diagnostics Signs

(let [signs {:DiagnosticSignError ""
             :DiagnosticSignWarn ""
             :DiagnosticSignInfo ""
             :DiagnosticSignHint ""}]
  (each [sign symbol (pairs signs)]
    (vim.fn.sign_define sign {:text symbol :texthl sign})))



; <<
;; >> Filetype Additions

(vim.filetype.add {:extension {:mdx "markdown"}
                   :filename {:Jenkinsfile "groovy"}})



; <<
;; >> Built-in LSP & Completion Setup

(set vim.opt.complete "o,.,w,b,u,t,kspell") ; lsp, current buffer, other buffers, tags, spelling
(set vim.opt.completeopt [:menu :menuone :popup :noselect :fuzzy])
(set vim.opt.completefuzzycollect [:keyword :files :whole_line])

;; Global LspAttach
;; TODO: enable completion documentation in popup?
;; https://github.com/konradmalik/neovim-flake/blob/98cae51386bbb3c47f935590c8a5129a79698084/config/nvim/lua/pde/lsp/capabilities/textDocument_completion.lua
;; Might be too complex
(vim.api.nvim_create_autocmd :LspAttach
  {:callback (fn [args]
               (let [client (assert (vim.lsp.get_client_by_id args.data.client_id))]
                 ; Disable semantic tokens for clojure_lsp to preserve treesitter highlighting
                 ; TODO: migrate to setting :semantic-tokens? to false once Neovim is updated https://clojure-lsp.io/settings/#all-settings
                 (when (= client.name "clojure_lsp")
                   (tset client.server_capabilities :semanticTokensProvider nil))
                 ; Enable built-in auto-completion
                 (when (client:supports_method :textDocument/completion)
                   (vim.lsp.completion.enable true client.id args.buf {:autotrigger true}))
                 (when (client:supports_method :textDocument/inlineCompletion)
                   (vim.lsp.inline_completion.enable true {:bufnr args.buf}))))})

; LSP keymaps
(vim.keymap.set [:n :v] :grf
                #(vim.lsp.buf.format {:async true :timeout_ms 1000})
                {:desc "vim.lsp.buf.format()"})
(vim.keymap.set [:n :v] :grd
                #(vim.lsp.buf.definition {})
                {:desc "vim.lsp.buf.definition()"})

;; Custom LSP servers (only for special cases)
(vim.lsp.config :clojure_lsp
  {:init_options {:cljfmt-config-path (.. (vim.fn.stdpath "config") "/config/.cljfmt.edn")}})

(vim.lsp.config :lua_ls
  {:settings {:Lua {:diagnostics {:globals [:vim :P]}
                    :workspace {:library (vim.api.nvim_list_runtime_paths)}}}})

(vim.lsp.config :fennel_language_server
  {:single_file_support true
   :settings {:fennel {:diagnostics {:globals [:vim :jit :comment]}
                       :workspace {:library (vim.api.nvim_list_runtime_paths)}}}})



; <<
;; >> Completion Keymaps

(fn pumvisible [] (not= 0 (vim.fn.pumvisible)))
(vim.keymap.set :i :<C-Space> :<C-x><C-o>)
(vim.keymap.set :i :<Tab> #(if (pumvisible) :<C-n> :<Tab>) {:expr true})
(vim.keymap.set :i :<S-Tab> #(if (pumvisible) :<C-p> :<C-d>) {:expr true})
(vim.keymap.set :i :<C-y> vim.lsp.inline_completion.get)
(vim.keymap.set :i :<C-d> #(if (pumvisible) (string.rep :<C-n> 5) :<C-d>) {:expr true})
(vim.keymap.set :i :<C-u> #(if (pumvisible) (string.rep :<C-p> 5) :<C-u>) {:expr true})



; <<
;; >> Plugin Manager Bootstrap

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



; <<
;; >> Plugins

(let [lazy (require "lazy")
      {: autoload} (require :nfnl.module)
      lazy-status (autoload :lazy.status)
      ntn (autoload :nvim-tmux-navigation)
      telescope (autoload :telescope)
      telescope-actions (autoload :telescope.actions)
      telescope-builtin (autoload :telescope.builtin)
      snacks (autoload :snacks)]
  (lazy.setup
    [{1 :Olical/nfnl
      :ft :fennel}


     ;; >> LSP & Language Support
     {1 :williamboman/mason.nvim
      :cmd "Mason"
      :keys [{1 :<leader>cm 2 :<cmd>Mason<cr> :desc "Mason"}]
      :opts {}}

     ; To support new languages, add it's language server here
     {1 :williamboman/mason-lspconfig.nvim
      :dependencies [:williamboman/mason.nvim :neovim/nvim-lspconfig]
      :opts {:ensure_installed [:clojure_lsp :fennel_language_server
                                :rust_analyzer :terraformls
                                :kotlin_lsp :copilot]
                                ; Disabled due to js exploit:
                                ;:pyright :ts_ls
             :automatic_enable true}}

     ;; Treesitter (main branch with auto-install)
     {1 :nvim-treesitter/nvim-treesitter
      :branch "main"
      :build ":TSUpdate"
      :lazy false
      :config (fn []
                (let [ts (require :nvim-treesitter)
                      available (ts.get_available)]
                  (ts.install [; basic
                               :comment :regex
                               ; Config files
                               :dockerfile :json :yaml
                               ; Git
                               :git_config :git_rebase :gitattributes
                               :gitcommit :gitignore
                               ; Programming languages
                               :bash :lua :luadoc :fennel :clojure :java
                               :javascript :typescript :python :terraform :html
                               :nix :markdown])
                  (vim.api.nvim_create_autocmd :FileType
                    {:callback
                      (fn [args]
                        (let [ft args.match
                              lang (vim.treesitter.language.get_lang ft)]
                          (when (vim.tbl_contains available lang)
                            ;; Auto-install parsers on demand
                            (-> (ts.install lang)
                                (: :await #(do
                                             ;; Auto-enable highlighting for all files
                                             (vim.treesitter.start args.buf lang))))

                            ;; Auto-enable folding for all files
                            (when (not= (vim.fs.basename args.file) "init.fnl")
                              (set vim.wo.foldmethod "expr")
                              (set vim.wo.foldexpr "v:lua.vim.treesitter.foldexpr()")))))})))}



     ; <<
     ;; >> Clojure REPL (Essential)
     {1 :Olical/conjure
      :branch :main
      :ft [:clojure :fennel :python]
      :keys [{1 :<leader>eg
              2 #(let [eval (require :conjure.eval)]
                   (eval.command "(when-let [go! (or (ns-resolve 'user 'go!)
                                                     (ns-resolve 'user 'go))]
                                    (go!))"))
              :desc "user/go!"}
             {1 :<leader>es
              2 #(do (vim.cmd "w")
                     (let [eval (require :conjure.eval)
                           filename (vim.fn.expand "%:p")]
                       (eval.command (string.format "(nextjournal.clerk/show! \"%s\")" filename))))
              :desc "clerk/show!"}]
      :opts {:config
             {"mapping#prefix" "<leader>"
              "client#clojure#nrepl#refresh#backend" "clj-reload"
              ; Briefly highlight evaluated forms
              "highlight#enabled" true

              ;; Clojure
              ; TODO: possibly remove
              ; Disable the mapping for selecting a session as that collides with searching)
              ; files within a project
              "client#clojure#nrepl#mapping#session_select" false
              ; Disable auto-starting a babashka repl
              "client#clojure#nrepl#connection#auto_repl#enabled" false}}
      :config (fn [_ opts]
                (each [k v (pairs opts.config)]
                  (tset vim.g (string.format "conjure#%s" k) v)))}



     ; <<
     ;; >> File Navigation
     {1 :nvim-telescope/telescope.nvim
      :dependencies [:nvim-lua/plenary.nvim
                     :nvim-telescope/telescope-fzf-native.nvim
                     :nvim-telescope/telescope-ui-select.nvim
                     :nvim-telescope/telescope-file-browser.nvim]
      :cmd "Telescope"
      :keys [;; Find
             {1 :<leader>ff 2 "<cmd>Telescope find_files<cr>" :desc "Find files"}
             {1 :<leader>fy 2 "<cmd>Telescope filetypes<cr>" :desc "Filetypes"}
             {1 "<leader>fr"
              2 #(let [; % gets the current buffer's path
                       ; :h gets the full path
                       buffer-relative-path (vim.call "expand" "%:h")]
                   (telescope.extensions.file_browser.file_browser
                    {:cwd buffer-relative-path}))
              :desc "Browse relative to buffer"}
             {1 "<leader>fh" 2 "<cmd>Telescope help_tags<CR>" :desc "Help tags"}
             {1 :<leader>fb
              2 #(telescope-builtin.buffers {:sort_mru true :sort_lastused true})
              :desc "Buffers"}
             ;; Search
             {1 "<leader>ss" 2 "<cmd>Telescope live_grep<CR>" :desc "Search project file contents"}
             {1 "<leader>s*" 2 "<cmd>Telescope grep_string<CR>" :desc "Search current word"}
             {1 "<leader>sr"
              2 #(let [; % gets the current buffer's path
                       ; :h gets the full path
                       buffer-relative-path (vim.call "expand" "%:h")]
                   (telescope-builtin.live_grep {:cwd buffer-relative-path}))}

             ;; Diagnostics
             ;; TODO: Move these elsewhere?
             {1 "<leader>dn" 2 #(vim.diagnostic.goto_next {:float {:border "rounded"}})
              :desc "Next"}
             {1 "<leader>dp" 2 #(vim.diagnostic.goto_prev {:float {:border "rounded"}})
              :desc "Previous"}]
      :opts {:defaults
             {:mappings
              {:i {; Normally when you press <esc> it puts you in normal mode in
                   ; telescope. This binding skips that to just exit.
                   "<esc>" (fn [...] (telescope-actions.close ...))
                   ; Add easier movement keys
                   "<C-j>" (fn [...] (telescope-actions.move_selection_next ...))
                   "<C-k>" (fn [...] (telescope-actions.move_selection_previous ...))

                   ; Show the mappings for the current picker
                   "<C-h>" (fn [...] telescope-actions.which_key ...)}}}
             :extensions
             {:fzf {}
              :ui-select {}
              :file_browser {}}}
      :config (fn [_ opts]
                (telescope.setup opts)
                (each [name _ (pairs opts.extensions)]
                  (telescope.load_extension name)))}



     ; <<
     ;; >> UI & Theme
     {1 :rebelot/kanagawa.nvim
      :enabled false
      :priority 1000 ; Load early
      :opts {; dim inactive window `:h hl-NormalNC`
             :dimInactive true
             :overrides #{"@comment.todo" {:link "@comment.note"}}}
      :config (fn [_ opts]
                (let [k (require :kanagawa)]
                  (k.setup opts))
                (vim.cmd "colorscheme kanagawa"))}
     {1 :p00f/alabaster.nvim
      :priority 1000 ; Load early
      :config #(do
                 (set vim.g.alabaster_floatborder true)
                 (vim.cmd "colorscheme alabaster"))}

     {1 :nvim-lualine/lualine.nvim
      :dependencies [:kyazdani42/nvim-web-devicons]
      :opts {:sections {:lualine_a [:filename]
                        :lualine_b [:branch :diff :diagnostics]
                        :lualine_c [:searchcount]
                        :lualine_x [{1 lazy-status.updates
                                     :cond lazy-status.has_updates
                                     :color {:fg "#ff9e64"}}]
                        :lualine_y []
                        :lualine_z [:location]}}}



     ; <<
     ;; >> Quality of Life
     :arp242/auto_mkdir2.vim    ; Auto-create directories

     {1 :folke/snacks.nvim
      :priority 1000
      :opts {:bigfile {:enabled true}
             :input {:enabled true}
             :notifier {:enabled true}
             :lazygit {:enabled true
                       :config {:gui {:scrollHeight 10}
                                :git {:overrideGpg true}
                                ; Based on: https://github.com/jesseduffield/lazygit/blob/11c7203db6776427906fb0fd54890ded59001989/pkg/config/editor_presets.go#L56
                                :os (let [base-cmd "nvim --server \"$NVIM\" "
                                          combine (fn [parts] (table.concat parts "; "))]
                                      {:edit (combine [(.. base-cmd "--remote-send \"q\"")
                                                       (.. base-cmd "--remote {{filename}}")])
                                       :editAtLine (combine [(.. base-cmd "--remote-send \"q\"")
                                                             (.. base-cmd "--remote {{filename}}")
                                                             (.. base-cmd "--remote-send \":{{line}}<CR>\"")])
                                       :openDirInEditor (combine [(.. base-cmd "--remote-send \"q\"")
                                                                  (.. base-cmd "--remote {{dir}}")])})}}}
      :init #(vim.api.nvim_create_user_command :G
               #(snacks.lazygit)
               {:desc "Open lazygit in current repo root"})}

     {1 :eraserhd/parinfer-rust
      :build "cargo build --release"}

     {1 :alexghergh/nvim-tmux-navigation
      :opts {}
      :keys [{1 "<C-h>" 2 #(ntn.NvimTmuxNavigateLeft) :desc "Navigate Left"}
             {1 "<C-j>" 2 #(ntn.NvimTmuxNavigateDown) :desc "Navigate Left"}
             {1 "<C-k>" 2 #(ntn.NvimTmuxNavigateUp) :desc "Navigate Left"}
             {1 "<C-l>" 2 #(ntn.NvimTmuxNavigateRight) :desc "Navigate Left"}]}

     {1 :folke/which-key.nvim
      :event :VeryLazy
      :keys [{1 "fd" 2 "<ESC>" :desc "Quick Escape" :mode :i}]
      :opts {:notify false}}]
     ; <<

    ;; Lazy.nvim config
    {:ui {:border "rounded"}
     :performance {:rtp {:disabled_plugins ["gzip" "matchit" "matchparen"
                                            "netrwPlugin" "tarPlugin" "tohtml"
                                            "tutor" "zipPlugin"]}}}))



; <<
;; >> Utility Commands

(vim.api.nvim_create_user_command :Nohl :nohl {})
(vim.api.nvim_create_user_command :Tab
  (fn [opts]
    (let [width (tonumber opts.args)]
      (set vim.bo.tabstop width)
      (set vim.bo.shiftwidth width)
      (set vim.bo.softtabstop width)))
  {:nargs 1 :desc "Set tab width for current buffer"})

; <<
nil
