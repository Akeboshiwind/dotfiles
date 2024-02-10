-- plugins/lsp/init.lua

local nvim_lspconfig_cfg = {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason.nvim",
        "nvim-lua/lsp-status.nvim",
        "folke/which-key.nvim",
        "nvim-telescope/telescope.nvim",
        "kosayoda/nvim-lightbulb",
        {
            "j-hui/fidget.nvim",
            event = "LspAttach",
            opts = {
            },
        },
    },
}

function nvim_lspconfig_cfg.config()
    -- require("plugins.lang.neodev").setup()
    require("plugins.lang.python-tools").setup()
    require("plugins.lang.rust-tools").setup()
    require("plugins.lang.conjure").setup()
end

return {
    nvim_lspconfig_cfg,
    "kosayoda/nvim-lightbulb",
    { import = "plugins.lsp.mason" },
    { import = "plugins.lsp.null-ls" },
}
