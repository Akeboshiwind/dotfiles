-- [nfnl] Compiled from init.fnl by https://github.com/Olical/nfnl, do not edit.
vim.g.mapleader = ","
local lazypath = (vim.fn.stdpath("data") .. "/lazy")
local function ensure(user, repo, branch)
  local install_path = (lazypath .. "/" .. repo)
  local branch0 = (branch or "main")
  if not vim.loop.fs_stat(install_path) then
    return vim.fn.system({"git", "clone", "--filter=blob:none", ("https://github.com/" .. user .. "/" .. repo .. ".git"), ("--branch=" .. branch0), install_path})
  else
    return (vim.opt.rtp):prepend(install_path)
  end
end
ensure("folke", "lazy.nvim", "stable")
ensure("Olical", "nfnl")
local lazy = require("lazy")
lazy.setup("plugins", {dev = {path = "~/prog/prog/nvim/"}, ui = {border = "single", icons = {cmd = "\226\140\152", config = "\240\159\155\160", event = "\240\159\147\133", ft = "\240\159\147\130", init = "\226\154\153", keys = "\240\159\151\157", plugin = "\240\159\148\140", runtime = "\240\159\146\187", source = "\240\159\147\132", start = "\240\159\154\128", task = "\240\159\147\140"}}, checker = {enabled = true, check_pinned = true}, performance = {rtp = {disabled_plugins = {"gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin"}}}})
_G.P = function(...)
  return print(vim.inspect(...))
end
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.inccommand = "nosplit"
vim.opt.updatetime = 1000
vim.cmd("filetype plugin indent on")
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.filetype.add({extension = {mdx = "markdown"}, filename = {Jenkinsfile = "groovy"}})
vim.opt.signcolumn = "yes"
vim.cmd("highlight! link SignColumn LineNr")
do
  local sign__3esymbol = {DiagnosticSignError = "\238\170\135", DiagnosticSignWarn = "\238\169\172", DiagnosticSignInfo = "\238\169\180", DiagnosticSignHint = "\239\132\170"}
  for sign, symbol in pairs(sign__3esymbol) do
    vim.fn.sign_define(sign, {text = symbol, texthl = sign, linelh = "", numlh = ""})
  end
end
if (0 ~= vim.fn.exists("+termguicolors")) then
  vim.opt.termguicolors = true
else
end
vim.opt.spelllang = "en_gb"
vim.opt.spell = true
vim.opt.spelloptions = "camel"
vim.opt.spellcapcheck = ""
return nil
