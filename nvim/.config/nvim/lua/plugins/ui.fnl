; plugins/ui.fnl
(local util (require "util"))

[{1 :rebelot/kanagawa.nvim
  :enable true
  :priority 1000 ; Load early
  :config #(let [{: setup} (require "kanagawa")]
             (setup {; dim inactive window `:h hl-NormalNC`
                     :dimInactive true})
             (vim.cmd "colorscheme kanagawa"))}

 {1 :nvim-lualine/lualine.nvim
  :dependencies [:kyazdani42/nvim-web-devicons]
  :opts {:sections {:lualine_a [:filename]
                    :lualine_b [:branch :diff :diagnostics]
                    :lualine_c [:searchcount]

                    :lualine_x [{1 (. (require "lazy.status") :updates)
                                 :cond (. (require "lazy.status") :has_updates)
                                 :color {:fg "#ff9e64"}}]
                    :lualine_y []
                    :lualine_z [:location]}}}

 {1 :rcarriga/nvim-notify
  :init #(util.on_very_lazy #(set vim.notify (require "notify")))
  :opts {:timeout 3000
         ; Ensure notifications are always on top
         :on_open #(vim.api.nvim_win_set_config $1 {:zindex 100})
         ; Ensure a reasonable max size
         :max_height #(math.floor (* vim.o.lines 0.75))
         :max_width #(math.floor (* vim.o.columns 0.75))}}

 {1 :alexghergh/nvim-tmux-navigation
  :opts {}
  :keys [{1 "<C-h>" 2 #((. (require "nvim-tmux-navigation") :NvimTmuxNavigateLeft)) :desc "Navigate Left"}
         {1 "<C-j>" 2 #((. (require "nvim-tmux-navigation") :NvimTmuxNavigateDown)) :desc "Navigate Left"}
         {1 "<C-k>" 2 #((. (require "nvim-tmux-navigation") :NvimTmuxNavigateUp)) :desc "Navigate Left"}
         {1 "<C-l>" 2 #((. (require "nvim-tmux-navigation") :NvimTmuxNavigateRight)) :desc "Navigate Left"}]}]
