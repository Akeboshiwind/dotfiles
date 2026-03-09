(local work-dir (os.getenv "HOME"))
(local cwd (vim.fn.getcwd))
(local theme (if (string.find cwd (.. work-dir "/prog/work") 1 true)
                 :tokyonight-night
                 :kanagawa-wave))

[{1 :rebelot/kanagawa.nvim
  :opts {:dimInactive true
         :overrides #{"@comment.todo" {:link "@comment.note"}}}}
 {1 :p00f/alabaster.nvim}
 {1 :LazyVim/LazyVim
  :opts {:colorscheme theme}}
 {1 :folke/which-key.nvim
  :opts {:preset :modern}}
 {1 :snacks.nvim
  :opts {:indent {:enabled false}}}]
