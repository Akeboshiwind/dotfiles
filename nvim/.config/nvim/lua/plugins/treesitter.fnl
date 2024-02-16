; plugins/treesitter.fnl

[{1 :nvim-treesitter/nvim-treesitter
  ;:dir "~/prog/prog/assorted/nvim-treesitter"}]
  :build ":TSUpdate"
  :dependencies [(comment 
                   {1 :nvim-treesitter/playground
                    :cmd "TSPlaygroundToggle"})]
  :opts {:ensure_installed ["comment" "regex"]
         :auto_install true

         :highlight {:enable true}
         :indent {:enable false}

         ;:playground {:enable true}
         :query_linter {:enable true
                        :use_virtual_text true
                        :lint_events [:BufWrite :CursorHold]}}
  :config (fn [_ opts]
            (let [{: setup} (require "nvim-treesitter.configs")]
              (setup opts)))}]
