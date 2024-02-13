-- plugins/nvim-tmux-navigation.lua
-- Seamless navigation between tmux panes and vim splits

return {
    {
        "alexghergh/nvim-tmux-navigation",
        opts = {},
        -- stylua: ignore
        keys = {
            {"<C-h>", function() require("nvim-tmux-navigation").NvimTmuxNavigateLeft() end,  desc="Navigate Left" },
            {"<C-j>", function() require("nvim-tmux-navigation").NvimTmuxNavigateDown() end,  desc="Navigate Left" },
            {"<C-k>", function() require("nvim-tmux-navigation").NvimTmuxNavigateUp() end,    desc="Navigate Left" },
            {"<C-l>", function() require("nvim-tmux-navigation").NvimTmuxNavigateRight() end, desc="Navigate Left" },
        },
    },
}
