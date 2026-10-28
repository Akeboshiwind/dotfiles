-- [nfnl] lua/plugins/session.fnl
local function _1_()
  local function _2_()
    return require("config.session")["restore-on-start"]()
  end
  vim.api.nvim_create_autocmd("VimEnter", {once = true, callback = _2_})
  local function _3_()
    return vim.cmd("silent! %argdelete")
  end
  return vim.api.nvim_create_autocmd("User", {pattern = "PersistenceSavePre", callback = _3_})
end
local function _4_()
  return require("config.session").reset()
end
return {{"folke/persistence.nvim", init = _1_, keys = {{"<leader>qr", _4_, desc = "Reset Session"}}}}
