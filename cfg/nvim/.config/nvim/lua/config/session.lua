-- [nfnl] lua/config/session.fnl
local function bare_start_3f()
  return ((0 == vim.fn.argc(-1)) and ("" == vim.api.nvim_buf_get_name(0)) and vim.deep_equal({""}, vim.api.nvim_buf_get_lines(0, 0, -1, false)) and (0 < #vim.api.nvim_list_uis()))
end
local function restore_on_start()
  if bare_start_3f() then
    return vim.schedule(require("persistence").load)
  else
    return nil
  end
end
return {["restore-on-start"] = restore_on_start}
