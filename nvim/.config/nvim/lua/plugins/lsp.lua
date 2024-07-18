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
    wk.add({{"K", vim.lsp.buf.hover, desc = "Document symbol", buffer = bufnr}})
  else
  end
  wk.add({{{"<leader>r", group = "run"}, {"<leader>rn", vim.lsp.buf.rename, desc = "Rename symbol under cursor"}, {"<leader>rf", vim.lsp.buf.formatting, desc = "Format the buffer"}, {"<leader>a", group = "action"}, {"<leader>aa", vim.lsp.buf.code_action, desc = "Apply code action"}, {"<leader>g", group = "goto"}, {"<leader>gD", vim.lsp.buf.declaration, desc = "Declaration"}, {"<leader>gi", builtin.lsp_implementations, desc = "Implementation"}, {"<leader>gy", builtin.lsp_type_definitions, desc = "Type definition"}, {"<leader>gr", builtin.lsp_references, desc = "References"}, {"<leader>gs", builtin.lsp_document_symbols, desc = "Document Symbols"}, {"<leader>gS", builtin.lsp_workspace_symbols, desc = "Workspace Symbols"}}, buffer = bufnr})
  if (filetype ~= "clojure") then
    wk.add({{{"<leader>gd", builtin.lsp_definitions, desc = "Definition"}}, buffer = bufnr})
  else
  end
  return wk.add({{{"<leader>a", group = "action"}, {"<leader>aa", ":'<,'>Telescope lsp_range_code_actions<CR>", desc = "Apply code action"}}, mode = "v", buffer = bufnr})
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
