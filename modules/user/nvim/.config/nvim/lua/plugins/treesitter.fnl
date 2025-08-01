; plugins/treesitter.fnl
(local {: autoload} (require :nfnl.module))
(local ts (autoload :nvim-treesitter))
(local Set (autoload :util.set))

[{1 :nvim-treesitter/nvim-treesitter
  ;:dir "~/prog/prog/assorted/nvim-treesitter"
  :lazy false
  :branch :main
  :build ":TSUpdate"
  :opts {:ensure_installed ["comment" "regex"]}
  :config (fn [_ opts]
            (let [available (Set.from (ts.get_available))]
              ; Recreate ensure_installed
              (ts.install opts.ensure_installed)

              ; Recreate auto_install
              (each [lang _ (pairs available)]
                (vim.api.nvim_create_autocmd :FileType
                  {:pattern (vim.treesitter.language.get_filetypes lang)
                   :callback (fn [ev]
                               (-> (ts.install lang)
                                   (: :await #(vim.treesitter.start ev.buf lang))))}))))}]
