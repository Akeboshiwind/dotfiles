-- [nfnl] Compiled from lua/plugins/cmp.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_()
  vim.opt.completeopt = {"menu", "menuone", "noselect"}
  return nil
end
local function _2_()
  local cmp = require("cmp")
  local function _3_(fallback)
    if cmp.visible() then
      return cmp.select_next_item()
    else
      return fallback()
    end
  end
  local function _5_(fallback)
    if cmp.visible() then
      return cmp.select_prev_item()
    else
      return fallback()
    end
  end
  cmp.setup({mapping = {["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), {"i", "c"}), ["<CR>"] = cmp.mapping.confirm({select = true, behavior = cmp.ConfirmBehavior.Replace}), ["<C-e>"] = cmp.mapping({i = cmp.mapping.abort(), c = cmp.mapping.close()}), ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), {"i", "c"}), ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), {"i", "c"}), ["<Tab>"] = cmp.mapping(_3_, {"i", "c"}), ["<S-Tab>"] = cmp.mapping(_5_, {"i", "c"})}, sources = cmp.config.sources({{name = "copilot"}, {name = "path"}, {name = "conjure"}, {name = "nvim_lsp"}, {name = "rg", keyword_length = 4}, {name = "buffer"}})})
  cmp.setup.cmdline({"/", "?"}, {mapping = cmp.mapping.preset.cmdline(), sources = {{name = "buffer"}}})
  cmp.setup.cmdline(":", {mapping = cmp.mapping.preset.cmdline(), sources = cmp.config.sources({{name = "path"}, {name = "cmdline"}})})
  local wk = require("which-key")
  return wk.register({["<C-Space>"] = "Invoke completion", ["<CR>"] = "Confirm selection or fallback", ["<C-e>"] = "Close the completion menu", ["<C-u>"] = "Page up", ["<C-d>"] = "Page down", ["<TAB>"] = "Next completion item", ["<S-TAB>"] = "Prev completion item"}, {mode = "i"})
end
return {{"hrsh7th/nvim-cmp", dependencies = {"hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline", "lukas-reineke/cmp-rg"}, init = _1_, config = _2_}}
