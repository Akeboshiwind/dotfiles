-- [nfnl] Compiled from lua/plugins/lsp.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local util = autoload("util")
local wk = autoload("which-key")
local builtin = autoload("telescope.builtin")
local lspconfig = autoload("lspconfig")
local lsp_ui_window = autoload("lspconfig.ui.windows")
local nvim_lightbulb = autoload("nvim-lightbulb")
local cmp_nvim_lsp = autoload("cmp_nvim_lsp")
local function setup_mappings(bufnr)
  local filetype = vim.bo[bufnr].filetype
  if (filetype ~= "clojure") then
    wk.register({K = {vim.lsp.buf.hover, "Document symbol"}}, {buffer = bufnr})
  else
  end
  wk.register({r = {name = "run", n = {vim.lsp.buf.rename, "Rename symbol under cursor"}, f = {vim.lsp.buf.formatting, "Format the buffer"}}, a = {name = "action", a = {vim.lsp.buf.code_action, "Apply code action"}}, g = {name = "goto", D = {vim.lsp.buf.declaration, "Declaration"}, i = {builtin.lsp_implementations, "Implementation"}, y = {builtin.lsp_type_definitions, "Type definition"}, r = {builtin.lsp_references, "References"}, s = {builtin.lsp_document_symbols, "Document Symbols"}, S = {builtin.lsp_workspace_symbols, "Workspace Symbols"}}}, {prefix = "<leader>", buffer = bufnr})
  if (filetype ~= "clojure") then
    wk.register({g = {name = "goto", d = {builtin.lsp_definitions, "Definition"}}}, {prefix = "<leader>", buffer = bufnr})
  else
  end
  return wk.register({a = {name = "action", a = {":'<,'>Telescope lsp_range_code_actions<CR>", "Apply code action"}}}, {prefix = "<leader>", mode = "v", buffer = bufnr})
end
local function _4_()
  local function _5_(_client, bufnr)
    local function _6_()
      return nvim_lightbulb.update_lightbulb()
    end
    return vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {buffer = bufnr, callback = _6_})
  end
  return util.lsp["on-attach"](_5_)
end
local function _7_(_, opts)
  lsp_ui_window.default_options = {border = "rounded"}
  local function _8_(_client, bufnr)
    return setup_mappings(bufnr)
  end
  util.lsp["on-attach"](_8_)
  local capabilities = vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities(), cmp_nvim_lsp.default_capabilities(), (opts.capabilities or {}))
  for server, server_opts in pairs(opts.servers) do
    local final_server_opts = vim.tbl_deep_extend("force", {capabilities = vim.deepcopy(capabilities)}, (server_opts or {}))
    if opts.setup[server] then
      opts.setup[server](server, final_server_opts)
    else
      lspconfig[server].setup(final_server_opts)
    end
  end
  return nil
end
return {{"j-hui/fidget.nvim", event = "LspAttach", opts = {}}, {"kosayoda/nvim-lightbulb", init = _4_}, {"neovim/nvim-lspconfig", dependencies = {"williamboman/mason-lspconfig.nvim", "folke/which-key.nvim", "nvim-telescope/telescope.nvim"}, opts = {servers = {}, setup = {}}, config = _7_}}
