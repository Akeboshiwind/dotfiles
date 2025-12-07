-- [nfnl] lua/config/lazy.fnl
local lazypath = (vim.fn.stdpath("data") .. "/lazy")
local newline = "\n"
local function ensure(user, repo, branch)
  local install_path = (lazypath .. "/" .. repo)
  local branch0 = (branch or "main")
  local uv = (vim.uv or vim.loop)
  if not uv.fs_stat(install_path) then
    local out = vim.fn.system({"git", "clone", "--filter=blob:none", ("https://github.com/" .. user .. "/" .. repo .. ".git"), ("--branch=" .. branch0), install_path})
    if (vim.v.shell_error() ~= 0) then
      vim.api.nvim_echo({{("Failed to clone " .. repo .. newline), "ErrorMsg"}, {out, "WarningMsg"}, {(newline .. "Press any key to exit...")}})
      vim.fn.getchar()
      os.exit(1)
    else
    end
  else
  end
  return vim.opt.rtp:prepend(install_path)
end
ensure("folke", "lazy.nvim", "stable")
ensure("Olical", "nfnl")
local lazy = require("lazy")
return lazy.setup({spec = {{"LazyVim/LazyVim", import = "lazyvim.plugins"}, {import = "plugins"}}, defaults = {lazy = false, version = false}, install = {colorscheme = {"alabaster", "kanagawa"}}, checker = {enabled = true, notify = false}, performance = {rtp = {disabled_plugins = {"gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin"}}}})
