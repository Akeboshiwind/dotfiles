-- [nfnl] lua/config/autocmds.fnl
local function _1_()
  return vim.cmd("nohl")
end
return vim.api.nvim_create_user_command("Nohl", _1_, {})
