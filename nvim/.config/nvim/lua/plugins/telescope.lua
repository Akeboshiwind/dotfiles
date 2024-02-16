-- [nfnl] Compiled from lua/plugins/telescope.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_()
  return (require("telescope.builtin")).find_files({find_command = {"rg", "--hidden", "--glob", "!**/.git/**", "--files"}})
end
local function _2_()
  return (require("telescope.builtin")).git_files({cwd = "~/dotfiles"})
end
local function _3_()
  local buffer_relative_path = vim.call("expand", "%:h")
  return (require("telescope")).extensions.file_browser.file_browser({cwd = buffer_relative_path})
end
local function _4_()
  return (require("telescope.builtin")).buffers({sort_lastused = true})
end
local function _5_()
  local buffer_relative_path = vim.call("expand", "%:h")
  return (require("telescope.builtin")).live_grep({cwd = buffer_relative_path})
end
local function _6_()
  return (require("telescope.builtin")).grep_string({search = "TODO"})
end
local function _7_()
  return (require("telescope")).extensions.emoji.emoji()
end
local function _8_()
  return (require("telescope.builtin")).diagnostics({bufnr = 0})
end
local function _9_()
  return vim.diagnostic.goto_next({float = {border = "rounded"}})
end
local function _10_()
  return vim.diagnostic.goto_prev({float = {border = "rounded"}})
end
local function _11_(...)
  return (require("telescope.actions")).close(...)
end
local function _12_(...)
  return (require("telescope.actions")).move_selection_next(...)
end
local function _13_(...)
  return (require("telescope.actions")).move_selection_previous(...)
end
local function _14_(...)
  return (require("telescope.actions")).which_key(...)
end
local function _15_(_241)
  return vim.api.nvim_put({_241.value}, "c", false, true)
end
local function _16_(...)
  return (require("telescope._extensions.file_browser.actions")).create_from_prompt(...)
end
local function _17_(_, opts)
  local telescope = require("telescope")
  telescope.setup(opts)
  for extension, _cfg in pairs(opts.extensions) do
    telescope.load_extension(extension)
  end
  return nil
end
return {{"nvim-telescope/telescope-fzf-native.nvim", build = "make"}, {"folke/which-key.nvim", opts = {defaults = {["<leader>f"] = {name = "find"}, ["<leader>s"] = {name = "search"}, ["<leader>d"] = {name = "diagnostic"}, ["<leader>G"] = {name = "git"}}}}, {"nvim-telescope/telescope.nvim", dependencies = {"nvim-lua/plenary.nvim", "kyazdani42/nvim-web-devicons", "nvim-telescope/telescope-fzf-native.nvim", "nvim-telescope/telescope-ui-select.nvim", "nvim-telescope/telescope-file-browser.nvim", "xiyaowong/telescope-emoji.nvim"}, cmd = "Telescope", keys = {{"<leader>ff", _1_, desc = "Browse local files (inc hidden)"}, {"<leader>f.", _2_, desc = "Dotfiles"}, {"<leader>fr", _3_, desc = "Browse relative to buffer"}, {"<leader>fb", _4_, desc = "Buffers"}, {"<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags"}, {"<leader>fy", "<cmd>Telescope filetypes<CR>", desc = "File types"}, {"<leader>fc", "<cmd>Telescope colorscheme<CR>", desc = "Colorschemes"}, {"<leader>fm", "<cmd>Telescope keymaps<CR>", desc = "Mappings"}, {"<leader>fM", "<cmd>Telescope man_pages<CR>", desc = "Man Pages"}, {"<leader>fB", "<cmd>Telescope builtin<CR>", desc = "Builtins"}, {"<leader>ss", "<cmd>Telescope live_grep<CR>", desc = "Search project file contents"}, {"<leader>sr", _5_, desc = "Search relative to buffer"}, {"<leader>st", _6_, desc = "Search for TODOs"}, {"<leader>s*", "<cmd>Telescope grep_string<CR>", desc = "Search for word under cursor"}, {"<leader>s/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Fuzzy find in the current buffer"}, {"<leader>se", _7_, desc = "Emoji"}, {"<leader>dd", "<cmd>Telescope diagnostics<CR>", desc = "List all diagnostics"}, {"<leader>db", _8_, desc = "List buffer diagnostics"}, {"<leader>dn", _9_, desc = "Next"}, {"<leader>dp", _10_, desc = "Previous"}, {"<leader>Gb", "<cmd>Telescope git_branches<CR>", desc = "Branches"}}, opts = {defaults = {mappings = {i = {["<esc>"] = _11_, ["<C-j>"] = _12_, ["<C-k>"] = _13_, ["<C-h>"] = _14_}}}, extensions = {fzf = {}, ["ui-select"] = {}, emoji = {action = _15_}, file_browser = {mappings = {i = {["<C-c>"] = _16_}}}}}, config = _17_}}
