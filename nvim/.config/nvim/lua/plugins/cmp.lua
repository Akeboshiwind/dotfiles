-- [nfnl] Compiled from lua/plugins/cmp.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local cmp = autoload("cmp")
local wk = autoload("which-key")
local function _2_()
  vim.opt.completeopt = {"menu", "menuone", "noselect"}
  return nil
end
local function _3_()
  local function _4_(fallback)
    if cmp.visible() then
      return cmp.select_next_item()
    else
      return fallback()
    end
  end
  local function _6_(fallback)
    if cmp.visible() then
      return cmp.select_prev_item()
    else
      return fallback()
    end
  end
  cmp.setup({mapping = {["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), {"i", "c"}), ["<CR>"] = cmp.mapping.confirm({select = true, behavior = cmp.ConfirmBehavior.Replace}), ["<C-e>"] = cmp.mapping({i = cmp.mapping.abort(), c = cmp.mapping.close()}), ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), {"i", "c"}), ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), {"i", "c"}), ["<Tab>"] = cmp.mapping(_4_, {"i", "c"}), ["<S-Tab>"] = cmp.mapping(_6_, {"i", "c"})}, sources = cmp.config.sources({{name = "copilot"}, {name = "path"}, {name = "conjure"}, {name = "nvim_lsp"}, {name = "rg", keyword_length = 4}, {name = "buffer"}})})
  cmp.setup.cmdline({"/", "?"}, {mapping = cmp.mapping.preset.cmdline(), sources = {{name = "buffer"}}})
  cmp.setup.cmdline(":", {mapping = cmp.mapping.preset.cmdline(), sources = cmp.config.sources({{name = "path"}, {name = "cmdline"}})})
  return wk.add({{{"<C-Space>", desc = "Invoke completion"}, {"<CR>", desc = "Confirm selection or fallback"}, {"<C-e>", desc = "Close the completion menu"}, {"<C-u>", desc = "Page up"}, {"<C-d>", desc = "Page down"}, {"<TAB>", desc = "Next completion item"}, {"<S-TAB>", desc = "Prev completion item"}}, mode = "i"})
end
return {{"hrsh7th/nvim-cmp", dependencies = {"hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline", "lukas-reineke/cmp-rg"}, init = _2_, config = _3_}}
