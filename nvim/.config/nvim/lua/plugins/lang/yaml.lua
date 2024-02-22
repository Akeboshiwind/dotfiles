-- [nfnl] Compiled from lua/plugins/lang/yaml.fnl by https://github.com/Olical/nfnl, do not edit.
local function _3_(_1_)
  local _arg_2_ = _1_
  local dirname = _arg_2_["dirname"]
  return (string.match(dirname, "cloudformation") or string.match(dirname, "cfn"))
end
local function _6_(_4_)
  local _arg_5_ = _4_
  local dirname = _arg_5_["dirname"]
  return string.match(dirname, ".github/workflows")
end
--[[ {1 "neovim/nvim-lspconfig" :opts {:servers {:yamlls {:settings {:yaml {:customTags ["!And scalar" "!And mapping" "!And sequence" "!If scalar" "!If mapping" "!If sequence" "!Not scalar" "!Not mapping" "!Not sequence" "!Equals scalar" "!Equals mapping" "!Equals sequence" "!Or scalar" "!Or mapping" "!Or sequence" "!FindInMap scalar" "!FindInMap mappping" "!FindInMap sequence" "!Base64 scalar" "!Base64 mapping" "!Base64 sequence" "!Cidr scalar" "!Cidr mapping" "!Cidr sequence" "!Ref scalar" "!Ref mapping" "!Ref sequence" "!Sub scalar" "!Sub mapping" "!Sub sequence" "!GetAtt scalar" "!GetAtt mapping" "!GetAtt sequence" "!GetAZs scalar" "!GetAZs mapping" "!GetAZs sequence" "!ImportValue scalar" "!ImportValue mapping" "!ImportValue sequence" "!Select scalar" "!Select mapping" "!Select sequence" "!Split scalar" "!Split mapping" "!Split sequence" "!Join scalar" "!Join mapping" "!Join sequence"] :format {:enable true} :schemaStore {:enable true} :validate {:enable true}}}}}}} ]]
return {{"williamboman/mason.nvim", opts = {["ensure-installed"] = {["cfn-lint"] = true, actionlint = true, yamllint = true}}}, {"mfussenegger/nvim-lint", opts = {linters_by_ft = {yaml = {"cfn_lint", "actionlint", "yamllint"}}, linters = {cfn_lint = {ignore_exitcode = true, condition = _3_}, actionlint = {condition = _6_}}}}, nil}
