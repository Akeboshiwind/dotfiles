-- [nfnl] lua/config/agents.fnl
local function realpath(path)
  return (vim.uv.fs_realpath(path) or path)
end
local function list()
  local ran_3f, result
  local function _1_()
    return vim.system({"claude", "agents", "--json"}, {text = true}):wait(2000)
  end
  ran_3f, result = pcall(_1_)
  local parsed_3f, rows
  if (ran_3f and (0 == result.code)) then
    parsed_3f, rows = pcall(vim.json.decode, result.stdout)
  else
    parsed_3f, rows = false
  end
  if parsed_3f then
    local tbl_26_ = {}
    local i_27_ = 0
    for _, row in ipairs(rows) do
      local val_28_
      do
        row["cwd"] = realpath(row.cwd)
        val_28_ = row
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    return tbl_26_
  else
    return {}
  end
end
local function open_float()
  local width = math.floor((vim.o.columns * 0.9))
  local height = math.floor((vim.o.lines * 0.8))
  return vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {relative = "editor", style = "minimal", border = "rounded", width = width, height = height, row = math.floor(((vim.o.lines - height) / 2)), col = math.floor(((vim.o.columns - width) / 2))})
end
local function pick(prompt, on_choice)
  local win = open_float()
  local chosen = vim.fn.tempname()
  local fzf = ("agent-rows " .. vim.api.nvim_win_get_width(win) .. " | fzf --ansi --delimiter '\t' --with-nth 2 --no-sort --layout reverse" .. " --select-1 --exit-0 --prompt " .. vim.fn.shellescape((prompt .. "> ")) .. " > " .. vim.fn.shellescape(chosen))
  local function _5_(_, code)
    vim.api.nvim_win_close(win, true)
    if (code == 0) then
      on_choice(vim.split(vim.fn.readfile(chosen)[1], "\t")[1])
    elseif (code == 1) then
      vim.notify("No Claude agents", vim.log.levels.WARN)
    else
    end
    return vim.fn.delete(chosen)
  end
  vim.fn.jobstart({"sh", "-c", fzf}, {term = true, on_exit = _5_})
  return vim.cmd.startinsert()
end
return {list = list, pick = pick}
