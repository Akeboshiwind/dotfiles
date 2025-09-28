(let [root (vim.fn.fnamemodify "./.repro" ":p")]
  (each [_ name (ipairs [:config :data :state :cache])]
    (let [var-name (string.format "XDG_%s_HOME" (name:upper))]
      (tset vim.env var-name (.. root "/" name))))
  (vim.opt.packpath:append (.. root "/data/nvim/site")))

(fn gh [repo] (.. "https://github.com/" repo))

(local plugins
  [;; >> LSP & Language Support
   {:src (gh :williamboman/mason.nvim)
    :data {:opts {}
           :keys [{1 :<leader>cm 2 :<cmd>Mason<cr> :desc "Mason"}]
           :build "ls"}}

   ; To support new languages, add it's language server here
   {:src (gh :williamboman/mason-lspconfig.nvim)
    :data {:dependencies [(gh :williamboman/mason.nvim) (gh :neovim/nvim-lspconfig)]
           :opts {:ensure_installed [:clojure_lsp :fennel_language_server
                                     :rust_analyzer :terraformls
                                     :kotlin_lsp :copilot]
                                     ; Disabled due to js exploit:
                                     ;:pyright :ts_ls
                  :automatic_enable true}}}])

;; Copied from vim.pack.add
(fn packadd [spec]
  (vim.cmd.packadd {1 (vim.fn.escape spec.name " ") :bang true :magic {:file false}}))

(fn setup-name [package-name]
  (string.gsub package-name "%.nvim$" ""))

(fn plugin-setup [spec]
  (let [cfg spec.data]
    (if cfg.config
      (cfg.config spec cfg.opts)
      (if cfg.opts
        (let [name (setup-name spec.name)
              p (require name)
              opts (or cfg.opts {})]
          (p.setup opts))))))

(fn to-map [t]
  (collect [k v (pairs t)]
    (when (not= :number (type k))
      (values k v))))

(fn setup-keymaps [spec]
  (let [keymaps spec.data.keys]
    (each [_ k (ipairs (or keymaps []))]
      (let [mode (or k.mode :n)
            lhs (. k 1)
            rhs (. k 2)
            opts (to-map k)]
        (vim.keymap.set mode lhs rhs opts)))))

(fn once [f]
  (var run? false)
  (fn [...]
    (when (not run?)
      (set run? true)
      (f ...))))

(fn load-plugin [spec]
  (let [;cfg spec.data
        load (once
               (fn [args]
                 (let [spec args.spec]
                   ; TODO: Add `build` on update
                   (packadd spec)
                   (plugin-setup spec)
                   (setup-keymaps spec))))]
    (var lazy? false)
    ;(when cfg.ft
    ;  (set lazy? true)
    ;  (vim.api.nvim_create_autocmd :FileType
    ;    {:pattern cfg.ft
    ;     :once true
    ;     :callback #(load spec)}))
    (when (not lazy?)
      (load spec))))

;; Install nfnl
(vim.pack.add [{:src (gh :Olical/nfnl) :data {:ft [:*.fnl]}}]
              {:load load-plugin :confirm false})

(local {: map : mapcat : remove : some} (require :nfnl.core))

;; TODO: On install & update run `build` command
;; TODO: Build command should support shell commands, fn & vim commands
(vim.api.nvim_create_autocmd :PackChanged
  {:callback (fn [{: data}]
               (when (or (= data.kind :install) (= data.kind :update))
                 (print data.kind)))})

;; Install dependencies
(let [plugin-names (->> plugins (map #(if (= :string (type $)) $ $.src)))
      dependencies (->> plugins
                        (remove #(= :string (type $)))
                        (map #$.data)
                        (mapcat #(or $.dependencies []))
                        (remove #(some (fn [p] (= p $)) plugin-names)))]
  ; No need for custom load
  (vim.pack.add dependencies {:confirm false}))

;; Install plugins
;; TODO: Fix ordering of loading plugins (mason-lsp is installed before mason)
(vim.pack.add plugins {:load load-plugin :confirm false})
