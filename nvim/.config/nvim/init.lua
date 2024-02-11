-- .config/nvim/init.lua
--
-- >> Directory structure:
--  .
--  ├── init.lua
--  ├── lazy-lock.json
--  ├── lua
--  │   └── plugins
--  │       ├── <sub-topic>
--  │       │   └── <plugin-name>.lua
--  │       ├── ...
--  │       ├── <plugin-name>.lua
--  │       └── init.lua
--  └── local_plugins
--      └── <plugin-name>
--
-- Execution runs in the following order:
--
--
-- >> `init.vim`
--
-- Here we:
-- - Run config that doesn't belong anywhere else
-- - Install `lazy.nvim` if it isn't already installed
-- - Run setup for `lazy.nvim`
-- - This installs any missing plugins automatically and updates the lock file
--
--
--
-- >> `lazy-lock.json`
--
-- A lockfile for your plugins! At last!
--
--
--
-- >> `lua/plugins/<plugin-name>.lua`
--
-- These files contain the PluginSpec for the plugin and any dependencies
-- I try to keep related config loaded when the plugin itself is loaded
-- So stuff as config and keybinds will go in here
--
-- I also have a `lua/plugins/init.lua` file for plugins that don't
-- fit in a single small file
--
--
--
-- >> `lua/plugins/<sub-topic>/<plugin-name>.lua`
--
-- Sometimes I have multiple of a related plugin that I want to keep around
-- An example of this is themes
-- I put these under a `theme/` folder and enable only one of them

local cmd = vim.cmd
local fn = vim.fn
local opt = vim.opt
local g = vim.g

-- >> Package Manager

-- Map before loading lazy.nvim
vim.g.mapleader = ","

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
    dev = {
        path = "~/prog/prog/nvim/",
    },
    ui = {
        icons = {
            cmd = "⌘",
            config = "🛠",
            event = "📅",
            ft = "📂",
            init = "⚙",
            keys = "🗝",
            plugin = "🔌",
            runtime = "💻",
            source = "📄",
            start = "🚀",
            task = "📌",
        },
        border = "single",
    },
    checker = {
        enabled = true,
        check_pinned = true,
    },
})

-- >> Utils

function _G.P(...)
    print(vim.inspect(...))
end

-- >> Usability

opt.ignorecase = true -- In searches, ignore the case
opt.smartcase = true -- Unless there's an uppercase letter
opt.splitright = true -- Make splits to the right
opt.inccommand = "nosplit" -- Show live replacements with the :s command
opt.updatetime = 1000 -- Make the CursorHold event trigger after 1 second not 4

-- >> Indentation

-- Enable filetype specific .vim files to be loaded
cmd([[filetype plugin indent on]])

opt.tabstop = 4 -- Show existing tab with 4 spaces width
opt.shiftwidth = 4 -- When indenting with '>', use 4 spaces width
opt.expandtab = true -- On pressing tab, insert 4 spaces

-- >> Filetype conversions

vim.filetype.add({
    extension = {
        mdx = "markdown",
    },
    filename = {
        ["Jenkinsfile"] = "groovy",
    },
})

-- >> Disable built-in plugins

local disabled_built_ins = { "netrwPlugin", "man", "matchit" }

for i = 1, #disabled_built_ins do
    g["loaded_" .. disabled_built_ins[i]] = 1
end

-- >> Setup Diagnostic Signs

-- Always enable sign column
opt.signcolumn = "yes"
-- Link SignColumn & LignNr highlights
-- TODO: Maybe move this to theme specific config?
cmd([[highlight! link SignColumn LineNr]])

local sign_config = {
    DiagnosticSignError = "",
    DiagnosticSignWarn = "",
    DiagnosticSignInfo = "",
    DiagnosticSignHint = "",
}

for sign, symbol in pairs(sign_config) do
    fn.sign_define(sign, {
        text = symbol,
        texthl = sign,
        linehl = "",
        numhl = "",
    })
end

-- >> Setup Term Colors

if fn.exists("+termguicolors") ~= 0 then
    -- Tell nvim that terminal support truecolor
    -- If not turned on then the theme doesn't work
    -- Can test using the truecolor-test script in bin or at:
    -- https://gist.github.com/XVilka/8346728
    opt.termguicolors = true
end



-- >> Setup spell checking
-- Basic usage:
--  ]s - move to next misspelled word
--  z= - see suggestions
--  zg - add word to spellfile
-- See :help spell for more
-- TODO: Add custom spellfile for all words < 3 characters

vim.o.spelllang = 'en_gb'
vim.o.spell = true
-- Include camel case words
vim.o.spelloptions = 'camel'
-- Disable capitalization check
vim.o.spellcapcheck = ''
