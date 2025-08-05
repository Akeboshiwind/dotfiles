-- [nfnl] lua/plugins/conjure.fnl
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local wk = autoload("which-key")
local cfg = autoload("util.cfg")
local function _2_(_, _0, G)
  for k, v in pairs(cfg["merge-all"](G["conjure/config"])) do
    vim.g[string.format("conjure#%s", k)] = v
  end
  return wk.add({{"<leader>c", group = "display as comment"}, {"<leader>e", group = "eval"}, {"<leader>g", group = "goto"}, {"<leader>l", group = "log"}, {"<leader>r", group = "refresh"}, {"<leader>s", group = "session"}, {"<leader>t", group = "test"}, {"<leader>v", group = "view"}})
end
return {{"PaterJason/cmp-conjure", dependencies = {"hrsh7th/nvim-cmp"}}, {"Olical/conjure", branch = "main", ft = {"python"}, dependencies = {"PaterJason/cmp-conjure"}, ["conjure/config"] = {["mapping#prefix"] = "<leader>", ["client#clojure#nrepl#refresh#backend"] = "clj-reload", ["highlight#enabled"] = true}, config = _2_}}
