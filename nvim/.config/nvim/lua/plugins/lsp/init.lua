-- plugins/lsp/init.lua

local nvim_lspconfig_cfg = {
    'neovim/nvim-lspconfig',
    dependencies = {
        'nvim-lua/lsp-status.nvim',
        'folke/which-key.nvim',
        'nvim-telescope/telescope.nvim',
        'kosayoda/nvim-lightbulb',
    },
}

local lsp_status_cfg = require('plugins.lsp.lsp-status')
local mason_cfg = require('plugins.lsp.mason')

function nvim_lspconfig_cfg.config()
    mason_cfg.setup()
    lsp_status_cfg.setup()

    require("plugins.lang.neodev").setup()
    require("plugins.lang.python-tools").setup()
    require("plugins.lang.rust-tools").setup()
end

return {
    nvim_lspconfig_cfg,
    'kosayoda/nvim-lightbulb',
    lsp_status_cfg,
    mason_cfg,
}
