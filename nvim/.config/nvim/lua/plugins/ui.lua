-- [nfnl] Compiled from lua/plugins/ui.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local util = autoload("util")
local kanagawa = autoload("kanagawa")
local lazy_status = autoload("lazy.status")
local notify = autoload("notify")
local nvim_tmux_navigation = autoload("nvim-tmux-navigation")
local function _2_()
  kanagawa.setup({dimInactive = true})
  return vim.cmd("colorscheme kanagawa")
end
local function _3_()
  local function _4_()
    vim.notify = notify
    return nil
  end
  return util["on-very-lazy"](_4_)
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
  return nvim_tmux_navigation.NvimTmuxNavigateLeft()
end
local function _9_()
  return nvim_tmux_navigation.NvimTmuxNavigateDown()
end
local function _10_()
  return nvim_tmux_navigation.NvimTmuxNavigateUp()
end
local function _11_()
  return nvim_tmux_navigation.NvimTmuxNavigateRight()
end
return {{"rebelot/kanagawa.nvim", enable = true, priority = 1000, config = _2_}, {"nvim-lualine/lualine.nvim", dependencies = {"kyazdani42/nvim-web-devicons"}, opts = {sections = {lualine_a = {"filename"}, lualine_b = {"branch", "diff", "diagnostics"}, lualine_c = {"searchcount"}, lualine_x = {{lazy_status.updates, cond = lazy_status.has_updates, color = {fg = "#ff9e64"}}}, lualine_y = {}, lualine_z = {"location"}}}}, {"rcarriga/nvim-notify", init = _3_, opts = {timeout = 3000, on_open = _5_, max_height = _6_, max_width = _7_}}, {"alexghergh/nvim-tmux-navigation", opts = {}, keys = {{"<C-h>", _8_, desc = "Navigate Left"}, {"<C-j>", _9_, desc = "Navigate Left"}, {"<C-k>", _10_, desc = "Navigate Left"}, {"<C-l>", _11_, desc = "Navigate Left"}}}}
