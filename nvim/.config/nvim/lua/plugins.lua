-- plugins.lua
--
-- Loosely copied from:
-- https://github.com/wbthomason/dotfiles/blob/8a9ac03/neovim/.config/nvim/lua/plugins.lua
--
-- >> Documentation
--
-- This file is only loaded by the :Packer* commands setup in `init.lua`.
-- This allows us to lazyload packer so it has nearly no cost.
--
-- To do this we setup a function `init()` which sets up what packages are
-- installed and their config.
-- 
-- `init()` is called each time a :Packer* command is called so config can be
-- easily reloaded.


-- So that we only require packer once
-- TODO: Does this mean that nvim has to be reloaded if packer is updated?
local packer = nil



-- Setup plugins
local function init()
    -- >> Packer init

    if packer == nil then
        packer = require('packer')
        packer.init({
            -- We set these up in `init.lua`
            disable_commands = true,
            display = {
                open_fn = function()
                    return require('packer.util').float({
                        border = 'single',
                        style = 'minimal',
                    })
                end,
            },
            profile = {
                enable = false,
                threshold = 1,
            },
        })
    end

    local use = packer.use
    packer.reset()



    -- >> 00-Base

    use {
        'wbthomason/packer.nvim',
        opt = true,
    }

    -- Some sensible defaults for vim
    use 'tpope/vim-sensible'

    -- Intelligently reopen files at your last edit position in Vim
    use 'farmergreg/vim-lastplace'

    -- Seamless navigation between tmux panes and vim splits
    use 'christoomey/vim-tmux-navigator'

    -- Automatically create paths that don't exist on buffer save
    use 'arp242/auto_mkdir2.vim'

    -- Git plugin
    use {
        'tpope/vim-fugitive',
        cmd = {
            'G', 'Git', 'Gclog'
        },
    }



    -- >> 01-Theme

    use { 'joshdick/onedark.vim', disable = true }

    use {
        'lifepillar/vim-solarized8',
        config = [[require('config.theme.vim-solarized8')]],
        disable = false,
    }

    use {
        'shaunsingh/moonlight.nvim',
        config = [[require('config.theme.moonlight')]],
        disable = true,
    }

    use {
        'folke/tokyonight.nvim',
        config = [[require('config.theme.tokyonight')]],
        disable = true,
    }

    --use 'shaunsingh/solarized.nvim'
    use { '~/prog/prog/assorted/solarized.nvim', disable = true }



    -- >> 02-Whichkey

    use {
        'folke/which-key.nvim',
        config = [[require('config.which-key')]],
    }



    -- >> 03-Telescope

    use { 'nvim-telescope/telescope-fzy-native.nvim', disable = true }

    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

    use {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/popup.nvim', 'nvim-lua/plenary.nvim' },
        after = { 'which-key.nvim', 'telescope-fzf-native.nvim' },
        config = [[require('config.telescope')]],
    }



    -- >> 04-Completion

    use {
        'hrsh7th/nvim-compe',
         config = [[require('config.nvim-compe')]],
    }



    -- >> 05-LSP

    use {
        'nvim-lua/lsp-status.nvim',
        config = [[require('config.lsp-status') require('config.theme.statusline')]],
    }

    -- TODO: Maybe lazyload?
    -- Might just cause a loop though 🤔
    use {
        'neovim/nvim-lspconfig',
        after = { 'lsp-status.nvim', 'which-key.nvim', 'telescope.nvim',
                  'trouble.nvim', 'nvim-lightbulb', 'lsp_signature.nvim' },
    }

    use {
        'williamboman/nvim-lsp-installer',
        run = [[require('config.nvim-lsp-installer').update_installed()]],
        config = [[require('config.nvim-lsp-installer').setup_commands()]],
        after = 'nvim-lspconfig',
        module = 'nvim-lsp-installer',
        cmd = 'LspUpdateAll',
    }

    use {
        "folke/trouble.nvim",
        requires = "kyazdani42/nvim-web-devicons",
        config = [[require("trouble").setup { }]],
    }

    use 'kosayoda/nvim-lightbulb'
    use 'ray-x/lsp_signature.nvim'


    -- >> Treesitter

    use {
        'nvim-treesitter/nvim-treesitter',
        -- '~/prog/prog/assorted/nvim-treesitter',
        run = ':TSUpdate',
        config = [[require('config.nvim-treesitter')]],
    }

    use {
        'nvim-treesitter/playground',
        cmd = { 'TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor' },
    }



    -- >> Motions

    use {
        'ggandor/lightspeed.nvim',
        config = [[require('config.lightspeed')]],
    }



    -- >> Filetypes

    use {
        'hashivim/vim-terraform',
        ft = 'terraform',
        config = [[require('config.vim-terraform')]],
    }

    use {
        'gurpreetatwal/vim-avro',
        ft = { 'avro', 'avdl' },
    }



    -- >> Clojure

    use {
        'Olical/conjure',
        tag = 'v4.20.0',
        ft = 'clojure',
        config = [[require('config.conjure')]],
    }

    use {
        'tami5/compe-conjure',
        after = { 'nvim-compe', 'conjure' },
    }

    use {
        'eraserhd/parinfer-rust',
        run = 'cargo build --release',
    }



    -- >> Rust

    use {
        'simrat39/rust-tools.nvim',
        after = { 'which-key.nvim', 'nvim-lspconfig',
                  'nvim-lsp-installer', 'telescope.nvim' },
        ft = 'rust',
        config = [[require('config.rust-tools')]],
    }



    -- >> Lua

    use {
        'folke/lua-dev.nvim',
        after = 'nvim-lsp-installer',
        ft = 'lua',
        config = [[require('config.lua-dev')]],
    }



    -- >> Vimspector
    use {
        'puremourning/vimspector',
        keys = ',D',
        after = { 'which-key.nvim' },
        config = [[require('config.vimspector')]],
    }
end



-- Return a table that mirrors `require('packer')` but calls our `init()` first
local plugins = setmetatable({}, {
  __index = function(_, key)
    init()
    return packer[key]
  end
})

return plugins
