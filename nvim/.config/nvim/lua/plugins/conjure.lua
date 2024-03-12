-- [nfnl] Compiled from lua/plugins/conjure.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_(_, opts)
  for k, v in pairs(opts.config) do
    vim.g[string.format("conjure#%s", k)] = v
  end
  return nil
end
return {{"PaterJason/cmp-conjure", dependencies = {"hrsh7th/nvim-cmp"}}, {"folke/which-key.nvim", opts = {defaults = {["<leader>l"] = {name = "log"}, ["<leader>e"] = {name = "eval"}, ["<leader>c"] = {name = "display as comment"}, ["<leader>g"] = {name = "goto"}}}}, {"Olical/conjure", version = "*", ft = {"python"}, dependencies = {"PaterJason/cmp-conjure"}, opts = {config = {["mapping#prefix"] = "<leader>", ["highlight#enabled"] = true}}, config = _1_}}
