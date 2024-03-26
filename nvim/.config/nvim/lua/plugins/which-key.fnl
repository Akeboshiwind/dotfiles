; plugins/which-key.fnl
(local {: autoload} (require :nfnl.module))
(local wk (autoload :which-key))

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
  :opts {:plugins {:spelling true}
         :triggers_blacklist {; Ignore escape key 'fd'
                              :i ["f"]}
         ; There are four ways to bind keys:
         ; 1. :keys on the plugin spec 
         ;    - This should be what you reach for first
         ; 2. wk.register
         ;    - Use this for dynamically registered bindings
         ; 3. This :defaults map
         ;    - Use this to setup folder names for keys
         ; 4. vim.keymap.set
         ;    - There should be no reason to use this
         :defaults {"<leader>w" { :name "window"}}}
  :config (fn [_ opts]
            (wk.setup opts)
            (wk.register opts.defaults))}]
