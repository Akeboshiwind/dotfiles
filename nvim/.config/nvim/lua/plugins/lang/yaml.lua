-- [nfnl] Compiled from fnl/plugins/lang/yaml.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_(_, opts)
  opts.ensure_installed = (opts.ensure_installed or {})
  vim.list_extend(opts.ensure_installed, {"cfn-lint", "actionlint", "yamllint"})
  return opts
end
local function _4_(_2_)
  local _arg_3_ = _2_
  local dirname = _arg_3_["dirname"]
  return (string.match(dirname, "cloudformation") or string.match(dirname, "cfn"))
end
local function _7_(_5_)
  local _arg_6_ = _5_
  local dirname = _arg_6_["dirname"]
  print(dirname)
  return string.match(dirname, ".github/workflows")
end
return {{"williamboman/mason.nvim", opts = _1_}, {"mfussenegger/nvim-lint", opts = {linters_by_ft = {yaml = {"cfn_lint", "actionlint", "yamllint"}}, linters = {cfn_lint = {ignore_exitcode = true, condition = _4_}, actionlint = {condition = _7_}}}}, {"neovim/nvim-lspconfig", opts = {servers = {yamlls = {settings = {yaml = {format = {enable = true}, validate = {enable = true}, schemaStore = {enable = true}, customTags = {"!And scalar", "!And mapping", "!And sequence", "!If scalar", "!If mapping", "!If sequence", "!Not scalar", "!Not mapping", "!Not sequence", "!Equals scalar", "!Equals mapping", "!Equals sequence", "!Or scalar", "!Or mapping", "!Or sequence", "!FindInMap scalar", "!FindInMap mappping", "!FindInMap sequence", "!Base64 scalar", "!Base64 mapping", "!Base64 sequence", "!Cidr scalar", "!Cidr mapping", "!Cidr sequence", "!Ref scalar", "!Ref mapping", "!Ref sequence", "!Sub scalar", "!Sub mapping", "!Sub sequence", "!GetAtt scalar", "!GetAtt mapping", "!GetAtt sequence", "!GetAZs scalar", "!GetAZs mapping", "!GetAZs sequence", "!ImportValue scalar", "!ImportValue mapping", "!ImportValue sequence", "!Select scalar", "!Select mapping", "!Select sequence", "!Split scalar", "!Split mapping", "!Split sequence", "!Join scalar", "!Join mapping", "!Join sequence"}}}}}}}}
