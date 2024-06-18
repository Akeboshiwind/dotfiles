-- [nfnl] Compiled from lua/plugins/flash.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local flash = autoload("flash")
--[[ "f" ]]
local function _2_()
  return flash.jump()
end
local function _3_()
  return flash.treesitter()
end
local function _4_()
  return flash.remote()
end
local function _5_()
  return flash.treesitter_search()
end
local function _6_()
  return flash.toggle()
end
return {{"folke/flash.nvim", event = "VeryLazy", opts = {modes = {char = {keys = {nil, "F", "t", "T"}, autohide = true, highlight = {backdrop = false}, multi_line = false}}}, keys = {{"s", _2_, mode = {"n", "x", "o"}, desc = "Flash"}, {"S", _3_, mode = {"n", "x", "o"}, desc = "Flash Treesitter"}, {"r", _4_, mode = "o", desc = "Remote Flash"}, {"R", _5_, mode = {"o", "x"}, desc = "Treesitter Search"}, {"<c-s>", _6_, mode = {"c"}, desc = "Toggle Flash Search"}}}}
