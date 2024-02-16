; plugins/which-key.fnl

[{1 :folke/which-key.nvim
  :init (fn []
          ; Leader is mapped in init.fnl
          (set vim.opt.timeoutlen 400))
  :event :VeryLazy
  :keys [{1 "fd" 2 "<ESC>" :desc "Quick Escape" :mode :i}
         {1 "*" 2 "g*" :desc "Search in buffer for match"}
         {1 "#" 2 "g#" :desc "Search in buffer for match, backwards"}

         {1 "<leader>x" 2 "<cmd>luafile %<CR>" :desc "Source lua buffer"}
         {1 "<leader>X" 2 "<cmd>source %<CR>" :desc "Source vim buffer"}

         {1 "<leader>w=" 2 "<cmd>wincmd =<CR>" :desc "Equalise all windows"}
         {1 "<leader>w+" 2 "<cmd>wincmd +<CR>" :desc "Increase window height"}
         {1 "<leader>w-" 2 "<cmd>wincmd -<CR>" :desc "Decrease window height"}
         {1 "<leader>w>" 2 "<cmd>wincmd <<CR>" :desc "Increase window width"}
         {1 "<leader>w<" 2 "<cmd>wincmd ><CR>" :desc "Decrease window width"}

         {1 "<C-Space>" 2 "<cmd>:WhichKey ''<CR>" :desc "Show base commands"}]
  :opts {:plugins { :spelling true}
         :triggers_blacklist {; Ignore escape key 'fd'
                              :i ["f"]}
         :defaults {"<leader>w" { :name "window"}}}
  :config (fn [_ opts]
            (let [wk (require "which-key")]
              (wk.setup opts)
              (wk.register opts.defaults)))}]
