-- [nfnl] Compiled from lua/plugins/ui.fnl by https://github.com/Olical/nfnl, do not edit.
local util = require("util")
local function _1_()
  local _let_2_ = require("kanagawa")
  local setup = _let_2_["setup"]
  setup({dimInactive = true})
  return vim.cmd("colorscheme kanagawa")
end
local function _3_()
  local function _4_()
    vim.notify = require("notify")
    return nil
  end
  return util.on_very_lazy(_4_)
end
local function _5_(_241)
  return vim.api.nvim_win_set_config(_241, {zindex = 100})
end
local function _6_()
  return math.floor((vim.o.lines * 0.75))
end
local function _7_()
  return math.floor((vim.o.columns * 0.75))
end
local function _8_()
  return (require("nvim-tmux-navigation")).NvimTmuxNavigateLeft()
end
local function _9_()
  return (require("nvim-tmux-navigation")).NvimTmuxNavigateDown()
end
local function _10_()
  return (require("nvim-tmux-navigation")).NvimTmuxNavigateUp()
end
local function _11_()
  return (require("nvim-tmux-navigation")).NvimTmuxNavigateRight()
end
return {{"rebelot/kanagawa.nvim", enable = true, priority = 1000, config = _1_}, {"nvim-lualine/lualine.nvim", dependencies = {"kyazdani42/nvim-web-devicons"}, opts = {sections = {lualine_a = {"filename"}, lualine_b = {"branch", "diff", "diagnostics"}, lualine_c = {"searchcount"}, lualine_x = {{(require("lazy.status")).updates, cond = (require("lazy.status")).has_updates, color = {fg = "#ff9e64"}}}, lualine_y = {}, lualine_z = {"location"}}}}, {"rcarriga/nvim-notify", init = _3_, opts = {timeout = 3000, on_open = _5_, max_height = _6_, max_width = _7_}}, {"alexghergh/nvim-tmux-navigation", opts = {}, keys = {{"<C-h>", _8_, desc = "Navigate Left"}, {"<C-j>", _9_, desc = "Navigate Left"}, {"<C-k>", _10_, desc = "Navigate Left"}, {"<C-l>", _11_, desc = "Navigate Left"}}}}
