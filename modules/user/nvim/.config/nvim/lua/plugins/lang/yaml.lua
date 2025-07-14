-- [nfnl] lua/plugins/lang/yaml.fnl
local function _2_(_1_)
  local dirname = _1_["dirname"]
  return (string.match(dirname, "cloudformation") or string.match(dirname, "cfn"))
end
local function _4_(_3_)
  local dirname = _3_["dirname"]
  return string.match(dirname, ".github/workflows")
end
--[[ {1 "neovim/nvim-lspconfig" :opts {:servers {:yamlls {:settings {:yaml {:customTags ["!And scalar" "!And mapping" "!And sequence" "!If scalar" "!If mapping" "!If sequence" "!Not scalar" "!Not mapping" "!Not sequence" "!Equals scalar" "!Equals mapping" "!Equals sequence" "!Or scalar" "!Or mapping" "!Or sequence" "!FindInMap scalar" "!FindInMap mappping" "!FindInMap sequence" "!Base64 scalar" "!Base64 mapping" "!Base64 sequence" "!Cidr scalar" "!Cidr mapping" "!Cidr sequence" "!Ref scalar" "!Ref mapping" "!Ref sequence" "!Sub scalar" "!Sub mapping" "!Sub sequence" "!GetAtt scalar" "!GetAtt mapping" "!GetAtt sequence" "!GetAZs scalar" "!GetAZs mapping" "!GetAZs sequence" "!ImportValue scalar" "!ImportValue mapping" "!ImportValue sequence" "!Select scalar" "!Select mapping" "!Select sequence" "!Split scalar" "!Split mapping" "!Split sequence" "!Join scalar" "!Join mapping" "!Join sequence"] :format {:enable true} :schemaStore {:enable true} :validate {:enable true}}}}}}} ]]
return {{"williamboman/mason.nvim", opts = {["ensure-installed"] = {["cfn-lint"] = true, actionlint = true, yamllint = true}}}, {"mfussenegger/nvim-lint", opts = {linters_by_ft = {yaml = {"cfn_lint", "actionlint", "yamllint"}}, linters = {cfn_lint = {ignore_exitcode = true, condition = _2_}, actionlint = {condition = _4_}}}}, {"kevinhwang91/nvim-ufo", opts = {["fold-queries"] = {yaml = "; services in docker-compose.yml\n     (block_mapping_pair\n       key: (_ (_ (string_scalar) @service_key))\n       value: (_ (_ (block_mapping_pair) @fold.custom))\n       (#eq? @service_key \"services\"))"}}}, nil}
