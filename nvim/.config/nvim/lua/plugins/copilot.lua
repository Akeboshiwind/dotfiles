-- [nfnl] Compiled from fnl/plugins/copilot.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_()
  return (require("copilot_cmp")).setup()
end
return {{"zbirenbaum/copilot-cmp", config = _1_}, {"zbirenbaum/copilot.lua", event = "VeryLazy", dependencies = {"zbirenbaum/copilot-cmp"}, opts = {panel = {enabled = false}, suggestion = {enabled = false}}}}
