-- plugins/lsp/init.lua

return {
    'kosayoda/nvim-lightbulb',
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'nvim-lua/lsp-status.nvim',
            'folke/which-key.nvim',
            'nvim-telescope/telescope.nvim',
            'kosayoda/nvim-lightbulb',
        },
    },
    require('plugins.lsp.lsp-status'),
    require('plugins.lsp.mason'),
}
