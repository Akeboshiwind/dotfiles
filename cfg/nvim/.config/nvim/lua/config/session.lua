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
local function file_buffer_3f(buf)
  return vim.tbl_contains({"", "acwrite"}, vim.bo[buf].buftype)
end
local function unsaved_buffers()
  local tbl_26_ = {}
  local i_27_ = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local val_28_
    if (file_buffer_3f(buf) and vim.bo[buf].modified) then
      local name = vim.api.nvim_buf_get_name(buf)
      if ("" == name) then
        val_28_ = "[No Name]"
      else
        val_28_ = vim.fn.fnamemodify(name, ":~:.")
      end
    else
      val_28_ = nil
    end
    if (nil ~= val_28_) then
      i_27_ = (i_27_ + 1)
      tbl_26_[i_27_] = val_28_
    else
    end
  end
  return tbl_26_
end
local function clear()
  local unsaved = unsaved_buffers()
  if (0 < #unsaved) then
    vim.notify(("Unsaved changes in:\n" .. table.concat(unsaved, "\n")), vim.log.levels.WARN)
    return false
  else
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop()
    end
    vim.cmd("silent! tabonly | silent! only")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if (vim.bo[buf].buflisted or ("terminal" == vim.bo[buf].buftype)) then
        vim.api.nvim_buf_delete(buf, {force = true})
      else
      end
    end
    return true
  end
end
local function reset()
  if clear() then
    vim.fn.delete(require("persistence").current())
    return Snacks.dashboard()
  else
    return nil
  end
end
return {["restore-on-start"] = restore_on_start, clear = clear, reset = reset}
