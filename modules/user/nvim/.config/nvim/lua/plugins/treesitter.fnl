; plugins/treesitter.fnl
(local {: autoload} (require :nfnl.module))
(local ts (autoload :nvim-treesitter))
(local Set (autoload :util.set))
(local cfg (autoload :util.cfg))

[{1 :nvim-treesitter/nvim-treesitter
  ;:dir "~/prog/prog/assorted/nvim-treesitter"
  :lazy false
  :branch :main
  :build ":TSUpdate"
  :treesitter/ensure-installed [:comment :regex]
  :config (fn [_ _ G]
            (let [available (Set.from (ts.get_available))]
              ; Recreate ensure_installed
              (ts.install (cfg.flatten-1 G.treesitter/ensure-installed))

              ; Recreate auto_install
              (each [lang _ (pairs available)]
                (vim.api.nvim_create_autocmd :FileType
                  {:pattern (vim.treesitter.language.get_filetypes lang)
                   :callback (fn [ev]
                               (-> (ts.install lang)
                                   (: :await #(vim.treesitter.start ev.buf lang))))}))))}]
