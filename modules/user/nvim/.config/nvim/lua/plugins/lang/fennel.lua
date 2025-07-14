-- [nfnl] lua/plugins/lang/fennel.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local lspconfig = autoload("lspconfig")
local test_harness = autoload("plenary.test_harness")
local wk = autoload("which-key")
local function _2_(_, _opts)
  local function test_current_file()
    local path = vim.fn.expand("%")
    local lua_path = path:gsub(".fnl$", ".lua")
    vim.cmd((":PlenaryBustedFile " .. lua_path))
    return test_harness.test_file(lua_path)
  end
  return wk.add({{"<leader>p", group = "plenary"}, {"<leader>pt", test_current_file, desc = "Test current file"}})
end
return {{"Olical/nfnl", ft = "fennel", config = _2_}, {"Olical/conjure", ft = {"fennel"}}, {"williamboman/mason.nvim", opts = {["ensure-installed"] = {["fennel-language-server"] = true}}}, {"kevinhwang91/nvim-ufo", opts = {["close-kinds"] = {fennel = {"fn_form"}}}}, {"neovim/nvim-lspconfig", opts = {servers = {fennel_language_server = {filetypes = {"fennel"}, root_dir = lspconfig.util.root_pattern("lua", "fnl"), single_file_support = true, settings = {fennel = {diagnostics = {globals = {"jit", "comment", "vim", "hs", "spoon"}}, workspace = {library = vim.api.nvim_list_runtime_paths()}}}}}}}}
