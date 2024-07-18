-- [nfnl] Compiled from lua/plugins/conjure.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local wk = autoload("which-key")
local function _2_(_, opts)
  for k, v in pairs(opts.config) do
    vim.g[string.format("conjure#%s", k)] = v
  end
  return wk.add({{"<leader>c", group = "display as comment"}, {"<leader>e", group = "eval"}, {"<leader>g", group = "goto"}, {"<leader>l", group = "log"}, {"<leader>r", group = "refresh"}, {"<leader>s", group = "session"}, {"<leader>t", group = "test"}, {"<leader>v", group = "view"}})
end
return {{"PaterJason/cmp-conjure", dependencies = {"hrsh7th/nvim-cmp"}}, {"Olical/conjure", version = "*", ft = {"python"}, dependencies = {"PaterJason/cmp-conjure"}, opts = {config = {["mapping#prefix"] = "<leader>", ["client#clojure#nrepl#refresh#backend"] = "clj-reload", ["highlight#enabled"] = true}}, config = _2_}}
