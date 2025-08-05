; plugins/telescope.fnl
(local {: autoload} (require :nfnl.module))
(local telescope (autoload :telescope))
(local builtin (autoload :telescope.builtin))
(local actions (autoload :telescope.actions))
(local file-browser-actions (autoload :telescope._extensions.file_browser.actions))
(local wk (autoload :which-key))
(local cfg (autoload :util.cfg))

[{1 :nvim-telescope/telescope-fzf-native.nvim
  :build "make"}
 {1 :nvim-telescope/telescope.nvim
  :dependencies [:nvim-lua/plenary.nvim
                 :kyazdani42/nvim-web-devicons
                 :nvim-telescope/telescope-fzf-native.nvim
                 :nvim-telescope/telescope-ui-select.nvim
                 :nvim-telescope/telescope-file-browser.nvim
                 :xiyaowong/telescope-emoji.nvim]
  :cmd "Telescope"
  :keys [; >> find
         {1 "<leader>ff"
          2 #(builtin.find_files
              {:find_command ["rg"
                              ; Show hidden files
                              "--hidden"
                              ; Ignore .git directory
                              "--glob"
                              "!**/.git/**"
                              "--files"]})
          :desc "Browse local files (inc hidden)"}
         {1 "<leader>f."
          2 #(builtin.git_files {:cwd "~/dotfiles"})
          :desc "Dotfiles"}
         {1 "<leader>fr"
          2 #(let [; % gets the current buffer's path
                   ; :h gets the full path
                   buffer-relative-path (vim.call "expand" "%:h")]
               (telescope.extensions.file_browser.file_browser
                {:cwd buffer-relative-path}))
          :desc "Browse relative to buffer"}
         {1 "<leader>fb"
          2 #(builtin.buffers {:sort_lastused true})
          :desc "Buffers"}
         {1 "<leader>fh" 2 "<cmd>Telescope help_tags<CR>" :desc "Help tags"}
         {1 "<leader>fy" 2 "<cmd>Telescope filetypes<CR>" :desc "File types"}
         {1 "<leader>fc" 2 "<cmd>Telescope colorscheme<CR>" :desc "Colorschemes"}
         {1 "<leader>fm" 2 "<cmd>Telescope keymaps<CR>" :desc "Mappings"}
         {1 "<leader>fM" 2 "<cmd>Telescope man_pages<CR>" :desc "Man Pages"}
         {1 "<leader>fB" 2 "<cmd>Telescope builtin<CR>" :desc "Builtins"}

         ; >> search
         {1 "<leader>ss" 2 "<cmd>Telescope live_grep<CR>" :desc "Search project file contents"}
         {1 "<leader>sr"
          2 #(let [; % gets the current buffer's path
                   ; :h gets the full path
                   buffer-relative-path (vim.call "expand" "%:h")]
               (builtin.live_grep {:cwd buffer-relative-path}))
          :desc "Search relative to buffer"}
         {1 "<leader>st"
          2 #(builtin.grep_string {:search "TODO"})
          :desc "Search for TODOs"}
         {1 "<leader>s*" 2 "<cmd>Telescope grep_string<CR>" :desc "Search for word under cursor"}
         {1 "<leader>s/" 2 "<cmd>Telescope current_buffer_fuzzy_find<CR>" :desc "Fuzzy find in the current buffer"}
         {1 "<leader>se"
          2 #(telescope.extensions.emoji.emoji)
          :desc "Emoji"}

         ; >> diagnostic
         {1 "<leader>dd" 2 "<cmd>Telescope diagnostics<CR>" :desc "List all diagnostics"}
         {1 "<leader>db"
          2 #(builtin.diagnostics {:bufnr 0})
          :desc "List buffer diagnostics"}
         {1 "<leader>dn"
          2 #(vim.diagnostic.goto_next {:float {:border "rounded"}})
          :desc "Next"}
         {1 "<leader>dp"
          2 #(vim.diagnostic.goto_prev {:float {:border "rounded"}})
          :desc "Previous"}

         ; >> Git
         {1 "<leader>Gb" 2 "<cmd>Telescope git_branches<CR>" :desc "Branches"}]
  :telescope/extensions
  {:fzf {}
   :ui-select {}
   :emoji {:action #(vim.api.nvim_put [$.value] :c false true)}
   :file_browser {:mappings
                  {:i {"<C-c>" (fn [...] (file-browser-actions.create_from_prompt ...))}}}}
  :opts {:defaults
         {:mappings
          {:i {; Normally when you press <esc> it puts you in normal mode in
               ; telescope. This binding skips that to just exit.
               "<esc>" (fn [...] (actions.close ...))
               ; Add easier movement keys
               "<C-j>" (fn [...] (actions.move_selection_next ...))
               "<C-k>" (fn [...] (actions.move_selection_previous ...))

               ; Show the mappings for the current picker
               "<C-h>" (fn [...] actions.which_key ...)}}}}
  :config (fn [_ opts G]
            ;; >> Setup
            (telescope.setup opts)

            ;; >> Add Telescope Extensions
            (each [extension _cfg (pairs (cfg.merge-all G.telescope/extensions))]
              (telescope.load_extension extension))
            ; >> Which-key groups
            (wk.add
              [{1 "<leader>f" :group "find"}
               {1 "<leader>s" :group "search"}
               {1 "<leader>d" :group "diagnostic"}
               {1 "<leader>G" :group "git"}]))}]
