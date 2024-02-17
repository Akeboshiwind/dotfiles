-- [nfnl] Compiled from lua/plugins/lang/yaml.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local update = _local_2_["update"]
local function _5_(_3_)
  local _arg_4_ = _3_
  local dirname = _arg_4_["dirname"]
  return (string.match(dirname, "cloudformation") or string.match(dirname, "cfn"))
end
local function _8_(_6_)
  local _arg_7_ = _6_
  local dirname = _arg_7_["dirname"]
  return string.match(dirname, ".github/workflows")
end
return {{"williamboman/mason.nvim", opts = {["ensure-installed"] = {["cfn-lint"] = true, actionlint = true, yamllint = true}}}, {"mfussenegger/nvim-lint", opts = {linters_by_ft = {yaml = {"cfn_lint", "actionlint", "yamllint"}}, linters = {cfn_lint = {ignore_exitcode = true, condition = _5_}, actionlint = {condition = _8_}}}}, {"neovim/nvim-lspconfig", opts = {servers = {yamlls = {settings = {yaml = {format = {enable = true}, validate = {enable = true}, schemaStore = {enable = true}, customTags = {"!And scalar", "!And mapping", "!And sequence", "!If scalar", "!If mapping", "!If sequence", "!Not scalar", "!Not mapping", "!Not sequence", "!Equals scalar", "!Equals mapping", "!Equals sequence", "!Or scalar", "!Or mapping", "!Or sequence", "!FindInMap scalar", "!FindInMap mappping", "!FindInMap sequence", "!Base64 scalar", "!Base64 mapping", "!Base64 sequence", "!Cidr scalar", "!Cidr mapping", "!Cidr sequence", "!Ref scalar", "!Ref mapping", "!Ref sequence", "!Sub scalar", "!Sub mapping", "!Sub sequence", "!GetAtt scalar", "!GetAtt mapping", "!GetAtt sequence", "!GetAZs scalar", "!GetAZs mapping", "!GetAZs sequence", "!ImportValue scalar", "!ImportValue mapping", "!ImportValue sequence", "!Select scalar", "!Select mapping", "!Select sequence", "!Split scalar", "!Split mapping", "!Split sequence", "!Join scalar", "!Join mapping", "!Join sequence"}}}}}}}}
