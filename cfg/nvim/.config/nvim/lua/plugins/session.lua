-- [nfnl] lua/plugins/session.fnl
local function _1_()
  local function _2_()
    return require("config.session")["restore-on-start"]()
  end
  return vim.api.nvim_create_autocmd("VimEnter", {once = true, callback = _2_})
end
return {{"folke/persistence.nvim", init = _1_}}
