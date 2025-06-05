; plugins/treesitter.fnl
(local {: autoload} (require :nfnl.module))
(local nvim-treesitter-config (autoload :nvim-treesitter.configs))

[{1 :nvim-treesitter/nvim-treesitter
  ;:dir "~/prog/prog/assorted/nvim-treesitter"}]
  :build ":TSUpdate"
  :dependencies [{1 :nvim-treesitter/playground
                  :cmd "TSPlaygroundToggle"}]
  :opts {:ensure_installed ["comment" "regex"]
         :auto_install true

         :highlight {:enable true}
         :indent {:enable false}

         ;:playground {:enable true}
         :query_linter {:enable true
                        :use_virtual_text true
                        :lint_events [:BufWrite :CursorHold]}}
  :config (fn [_ opts]
            (nvim-treesitter-config.setup opts))}]
