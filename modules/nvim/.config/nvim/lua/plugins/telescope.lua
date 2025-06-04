-- [nfnl] Compiled from lua/plugins/telescope.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local telescope = autoload("telescope")
local builtin = autoload("telescope.builtin")
local actions = autoload("telescope.actions")
local file_browser_actions = autoload("telescope._extensions.file_browser.actions")
local wk = autoload("which-key")
local function _2_()
  return builtin.find_files({find_command = {"rg", "--hidden", "--glob", "!**/.git/**", "--files"}})
end
local function _3_()
  return builtin.git_files({cwd = "~/dotfiles"})
end
local function _4_()
  local buffer_relative_path = vim.call("expand", "%:h")
  return telescope.extensions.file_browser.file_browser({cwd = buffer_relative_path})
end
local function _5_()
  return builtin.buffers({sort_lastused = true})
end
local function _6_()
  local buffer_relative_path = vim.call("expand", "%:h")
  return builtin.live_grep({cwd = buffer_relative_path})
end
local function _7_()
  return builtin.grep_string({search = "TODO"})
end
local function _8_()
  return telescope.extensions.emoji.emoji()
end
local function _9_()
  return builtin.diagnostics({bufnr = 0})
end
local function _10_()
  return vim.diagnostic.goto_next({float = {border = "rounded"}})
end
local function _11_()
  return vim.diagnostic.goto_prev({float = {border = "rounded"}})
end
local function _12_(...)
  return actions.close(...)
end
local function _13_(...)
  return actions.move_selection_next(...)
end
local function _14_(...)
  return actions.move_selection_previous(...)
end
local function _15_(...)
  do local _ = actions.which_key end
  return ...
end
local function _16_(_241)
  return vim.api.nvim_put({_241.value}, "c", false, true)
end
local function _17_(...)
  return file_browser_actions.create_from_prompt(...)
end
local function _18_(_, opts)
  telescope.setup(opts)
  for extension, _cfg in pairs(opts.extensions) do
    telescope.load_extension(extension)
  end
  return wk.add({{"<leader>f", group = "find"}, {"<leader>s", group = "search"}, {"<leader>d", group = "diagnostic"}, {"<leader>G", group = "git"}})
end
return {{"nvim-telescope/telescope-fzf-native.nvim", build = "make"}, {"nvim-telescope/telescope.nvim", dependencies = {"nvim-lua/plenary.nvim", "kyazdani42/nvim-web-devicons", "nvim-telescope/telescope-fzf-native.nvim", "nvim-telescope/telescope-ui-select.nvim", "nvim-telescope/telescope-file-browser.nvim", "xiyaowong/telescope-emoji.nvim"}, cmd = "Telescope", keys = {{"<leader>ff", _2_, desc = "Browse local files (inc hidden)"}, {"<leader>f.", _3_, desc = "Dotfiles"}, {"<leader>fr", _4_, desc = "Browse relative to buffer"}, {"<leader>fb", _5_, desc = "Buffers"}, {"<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags"}, {"<leader>fy", "<cmd>Telescope filetypes<CR>", desc = "File types"}, {"<leader>fc", "<cmd>Telescope colorscheme<CR>", desc = "Colorschemes"}, {"<leader>fm", "<cmd>Telescope keymaps<CR>", desc = "Mappings"}, {"<leader>fM", "<cmd>Telescope man_pages<CR>", desc = "Man Pages"}, {"<leader>fB", "<cmd>Telescope builtin<CR>", desc = "Builtins"}, {"<leader>ss", "<cmd>Telescope live_grep<CR>", desc = "Search project file contents"}, {"<leader>sr", _6_, desc = "Search relative to buffer"}, {"<leader>st", _7_, desc = "Search for TODOs"}, {"<leader>s*", "<cmd>Telescope grep_string<CR>", desc = "Search for word under cursor"}, {"<leader>s/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Fuzzy find in the current buffer"}, {"<leader>se", _8_, desc = "Emoji"}, {"<leader>dd", "<cmd>Telescope diagnostics<CR>", desc = "List all diagnostics"}, {"<leader>db", _9_, desc = "List buffer diagnostics"}, {"<leader>dn", _10_, desc = "Next"}, {"<leader>dp", _11_, desc = "Previous"}, {"<leader>Gb", "<cmd>Telescope git_branches<CR>", desc = "Branches"}}, opts = {defaults = {mappings = {i = {["<esc>"] = _12_, ["<C-j>"] = _13_, ["<C-k>"] = _14_, ["<C-h>"] = _15_}}}, extensions = {fzf = {}, ["ui-select"] = {}, emoji = {action = _16_}, file_browser = {mappings = {i = {["<C-c>"] = _17_}}}}}, config = _18_}}
