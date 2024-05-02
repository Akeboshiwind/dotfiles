; plugins/ui.fnl
(local {: autoload} (require :nfnl.module))
(local util (autoload :util))
(local kanagawa (autoload :kanagawa))
(local lazy-status (autoload :lazy.status))
(local notify (autoload :notify))
(local nvim-tmux-navigation (autoload :nvim-tmux-navigation))

[{1 :rebelot/kanagawa.nvim
  :enable true
  :priority 1000 ; Load early
  :config #(do
             (kanagawa.setup
               {; dim inactive window `:h hl-NormalNC`
                :dimInactive true
                :overrides (fn [_]
                             {"@comment.todo" {:link "@comment.note"}})})
             (vim.cmd "colorscheme kanagawa"))}

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

 {1 :rcarriga/nvim-notify
  :init #(util.on-very-lazy #(set vim.notify notify))
  :opts {:timeout 3000
         ; Ensure notifications are always on top
         :on_open #(vim.api.nvim_win_set_config $1 {:zindex 100})
         ; Ensure a reasonable max size
         :max_height #(math.floor (* vim.o.lines 0.75))
         :max_width #(math.floor (* vim.o.columns 0.75))}}

 {1 :alexghergh/nvim-tmux-navigation
  :opts {}
  :keys [{1 "<C-h>" 2 #(nvim-tmux-navigation.NvimTmuxNavigateLeft) :desc "Navigate Left"}
         {1 "<C-j>" 2 #(nvim-tmux-navigation.NvimTmuxNavigateDown) :desc "Navigate Left"}
         {1 "<C-k>" 2 #(nvim-tmux-navigation.NvimTmuxNavigateUp) :desc "Navigate Left"}
         {1 "<C-l>" 2 #(nvim-tmux-navigation.NvimTmuxNavigateRight) :desc "Navigate Left"}]}]
