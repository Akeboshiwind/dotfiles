-- [nfnl] init.fnl
_G.P = function(...)
  return print(vim.inspect(...))
end
vim.g.mapleader = ","
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.inccommand = "nosplit"
vim.opt.updatetime = 1000
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
vim.opt.spell = true
vim.opt.spelllang = "en_gb"
vim.opt.spelloptions = "camel"
vim.opt.spellcapcheck = ""
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.foldcolumn = "0"
vim.opt.foldtext = ""
vim.opt.foldlevelstart = 99
vim.opt.foldopen = ""
vim.opt.foldmethod = "marker"
vim.opt.foldmarker = ">>,<<"
vim.opt.viewoptions = "folds,cursor"
vim.api.nvim_create_autocmd({"BufWinLeave"}, {pattern = "?*", command = "mkview"})
vim.api.nvim_create_autocmd({"BufWinEnter"}, {pattern = "?*", command = "silent! loadview"})
if (0 ~= vim.fn.exists("+termguicolors")) then
  vim.opt.termguicolors = true
else
end
vim.cmd("highlight! link SignColumn LineNr")
do
  local signs = {DiagnosticSignError = "", DiagnosticSignWarn = "", DiagnosticSignInfo = "", DiagnosticSignHint = ""}
  for sign, symbol in pairs(signs) do
    vim.fn.sign_define(sign, {text = symbol, texthl = sign})
  end
end
vim.filetype.add({extension = {mdx = "markdown"}, filename = {Jenkinsfile = "groovy"}})
vim.opt.complete = "o,.,w,b,u,t,kspell"
vim.opt.completeopt = {"menu", "menuone", "popup", "noselect", "fuzzy"}
vim.opt.completefuzzycollect = {"keyword", "files", "whole_line"}
local function _2_(args)
  local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
  if client:supports_method("textDocument/completion") then
    vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
  else
  end
  if client:supports_method("textDocument/inlineCompletion") then
    return vim.lsp.inline_completion.enable(true, {bufnr = args.buf})
  else
    return nil
  end
end
vim.api.nvim_create_autocmd("LspAttach", {callback = _2_})
local function _5_()
  return vim.lsp.buf.format({async = true, timeout_ms = 1000})
end
vim.keymap.set({"n", "v"}, "grf", _5_, {desc = "vim.lsp.buf.format()"})
vim.lsp.config("clojure_lsp", {init_options = {["cljfmt-config-path"] = (vim.fn.stdpath("config") .. "/config/.cljfmt.edn")}})
vim.lsp.config("lua_ls", {settings = {Lua = {diagnostics = {globals = {"vim", "P"}}, workspace = {library = vim.api.nvim_list_runtime_paths()}}}})
vim.lsp.config("fennel_language_server", {single_file_support = true, settings = {fennel = {diagnostics = {globals = {"vim"}}, workspace = {library = vim.api.nvim_list_runtime_paths()}}}})
local function pumvisible()
  return (0 ~= vim.fn.pumvisible())
end
vim.keymap.set("i", "<C-Space>", "<C-x><C-o>")
local function _6_()
  if pumvisible() then
    return "<C-n>"
  else
    return "<Tab>"
  end
end
vim.keymap.set("i", "<Tab>", _6_, {expr = true})
local function _8_()
  if pumvisible() then
    return "<C-p>"
  else
    return "<C-d>"
  end
end
vim.keymap.set("i", "<S-Tab>", _8_, {expr = true})
vim.keymap.set("i", "<C-y>", vim.lsp.inline_completion.get)
local function _10_()
  if pumvisible() then
    return string.rep("<C-n>", 5)
  else
    return "<C-d>"
  end
end
vim.keymap.set("i", "<C-d>", _10_, {expr = true})
local function _12_()
  if pumvisible() then
    return string.rep("<C-p>", 5)
  else
    return "<C-u>"
  end
end
vim.keymap.set("i", "<C-u>", _12_, {expr = true})
local lazypath = (vim.fn.stdpath("data") .. "/lazy")
local function ensure(user, repo, branch)
  local install_path = (lazypath .. "/" .. repo)
  local branch0 = (branch or "main")
  if not vim.loop.fs_stat(install_path) then
    return vim.fn.system({"git", "clone", "--filter=blob:none", ("https://github.com/" .. user .. "/" .. repo .. ".git"), ("--branch=" .. branch0), install_path})
  else
    return vim.opt.rtp:prepend(install_path)
  end
end
ensure("folke", "lazy.nvim", "stable")
ensure("Olical", "nfnl")
do
  local lazy = require("lazy")
  local _let_15_ = require("nfnl.module")
  local autoload = _let_15_["autoload"]
  local lazy_status = autoload("lazy.status")
  local ntn = autoload("nvim-tmux-navigation")
  local telescope = autoload("telescope")
  local telescope_actions = autoload("telescope.actions")
  local telescope_builtin = autoload("telescope.builtin")
  local function _16_()
    local ts = require("nvim-treesitter")
    local available = ts.get_available()
    ts.install({"comment", "regex", "dockerfile", "json", "yaml", "git_config", "git_rebase", "gitattributes", "gitcommit", "gitignore", "bash", "lua", "luadoc", "fennel", "clojure", "java", "javascript", "typescript", "python", "terraform", "html", "nix", "markdown"})
    local function _17_(args)
      local ft = args.match
      local lang = vim.treesitter.language.get_lang(ft)
      if vim.tbl_contains(available, lang) then
        local function _18_()
          return vim.treesitter.start(args.buf, lang)
        end
        ts.install(lang):await(_18_)
        if (vim.fs.basename(args.file) ~= "init.fnl") then
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          return nil
        else
          return nil
        end
      else
        return nil
      end
    end
    return vim.api.nvim_create_autocmd("FileType", {callback = _17_})
  end
  local function _21_()
    local eval = require("conjure.eval")
    return eval.command("(when-let [go! (or (ns-resolve 'user 'go!)\n                                                     (ns-resolve 'user 'go))]\n                                    (go!))")
  end
  local function _22_()
    vim.cmd("w")
    local eval = require("conjure.eval")
    local filename = vim.fn.expand("%:p")
    return eval.command(string.format("(nextjournal.clerk/show! \"%s\")", filename))
  end
  local function _23_(_, opts)
    for k, v in pairs(opts.config) do
      vim.g[string.format("conjure#%s", k)] = v
    end
    return nil
  end
  local function _24_()
    local buffer_relative_path = vim.call("expand", "%:h")
    return telescope.extensions.file_browser.file_browser({cwd = buffer_relative_path})
  end
  local function _25_()
    return telescope_builtin.buffers({sort_mru = true, sort_lastused = true})
  end
  local function _26_()
    local buffer_relative_path = vim.call("expand", "%:h")
    return telescope_builtin.live_grep({cwd = buffer_relative_path})
  end
  local function _27_()
    return vim.diagnostic.goto_next({float = {border = "rounded"}})
  end
  local function _28_()
    return vim.diagnostic.goto_prev({float = {border = "rounded"}})
  end
  local function _29_(...)
    return telescope_actions.close(...)
  end
  local function _30_(...)
    return telescope_actions.move_selection_next(...)
  end
  local function _31_(...)
    return telescope_actions.move_selection_previous(...)
  end
  local function _32_(...)
    do local _ = telescope_actions.which_key end
    return ...
  end
  local function _33_(_, opts)
    telescope.setup(opts)
    for name, _0 in pairs(opts.extensions) do
      telescope.load_extension(name)
    end
    return nil
  end
  local function _34_()
    return {["@comment.todo"] = {link = "@comment.note"}}
  end
  local function _35_(_, opts)
    do
      local k = require("kanagawa")
      k.setup(opts)
    end
    return vim.cmd("colorscheme kanagawa")
  end
  local function _36_()
    return ntn.NvimTmuxNavigateLeft()
  end
  local function _37_()
    return ntn.NvimTmuxNavigateDown()
  end
  local function _38_()
    return ntn.NvimTmuxNavigateUp()
  end
  local function _39_()
    return ntn.NvimTmuxNavigateRight()
  end
  lazy.setup({{"Olical/nfnl", ft = "fennel"}, {"williamboman/mason.nvim", cmd = "Mason", keys = {{"<leader>cm", "<cmd>Mason<cr>", desc = "Mason"}}, opts = {}}, {"williamboman/mason-lspconfig.nvim", dependencies = {"williamboman/mason.nvim", "neovim/nvim-lspconfig"}, opts = {ensure_installed = {"clojure_lsp", "fennel_language_server", "rust_analyzer", "terraformls", "kotlin_lsp", "copilot"}, automatic_enable = true}}, {"nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate", config = _16_, lazy = false}, {"Olical/conjure", branch = "main", ft = {"clojure", "fennel", "python"}, keys = {{"<leader>eg", _21_, desc = "user/go!"}, {"<leader>es", _22_, desc = "clerk/show!"}}, opts = {config = {["mapping#prefix"] = "<leader>", ["client#clojure#nrepl#refresh#backend"] = "clj-reload", ["highlight#enabled"] = true, ["client#clojure#nrepl#connection#auto_repl#enabled"] = false, ["client#clojure#nrepl#mapping#session_select"] = false}}, config = _23_}, {"nvim-telescope/telescope.nvim", dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzf-native.nvim", "nvim-telescope/telescope-ui-select.nvim", "nvim-telescope/telescope-file-browser.nvim"}, cmd = "Telescope", keys = {{"<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files"}, {"<leader>fy", "<cmd>Telescope filetypes<cr>", desc = "Filetypes"}, {"<leader>fr", _24_, desc = "Browse relative to buffer"}, {"<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags"}, {"<leader>fb", _25_, desc = "Buffers"}, {"<leader>ss", "<cmd>Telescope live_grep<CR>", desc = "Search project file contents"}, {"<leader>s*", "<cmd>Telescope grep_string<CR>", desc = "Search current word"}, {"<leader>sr", _26_}, {"<leader>dn", _27_, desc = "Next"}, {"<leader>dp", _28_, desc = "Previous"}}, opts = {defaults = {mappings = {i = {["<esc>"] = _29_, ["<C-j>"] = _30_, ["<C-k>"] = _31_, ["<C-h>"] = _32_}}}, extensions = {fzf = {}, ["ui-select"] = {}, file_browser = {}}}, config = _33_}, {"rebelot/kanagawa.nvim", priority = 1000, opts = {dimInactive = true, overrides = _34_}, config = _35_}, {"nvim-lualine/lualine.nvim", dependencies = {"kyazdani42/nvim-web-devicons"}, opts = {sections = {lualine_a = {"filename"}, lualine_b = {"branch", "diff", "diagnostics"}, lualine_c = {"searchcount"}, lualine_x = {{lazy_status.updates, cond = lazy_status.has_updates, color = {fg = "#ff9e64"}}}, lualine_y = {}, lualine_z = {"location"}}}}, "tpope/vim-fugitive", "arp242/auto_mkdir2.vim", {"NeogitOrg/neogit", dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim"}, opts = {}}, {"eraserhd/parinfer-rust", build = "cargo build --release"}, {"alexghergh/nvim-tmux-navigation", opts = {}, keys = {{"<C-h>", _36_, desc = "Navigate Left"}, {"<C-j>", _37_, desc = "Navigate Left"}, {"<C-k>", _38_, desc = "Navigate Left"}, {"<C-l>", _39_, desc = "Navigate Left"}}}, {"folke/which-key.nvim", event = "VeryLazy", keys = {{"fd", "<ESC>", desc = "Quick Escape", mode = "i"}}, opts = {notify = false}}}, {ui = {border = "rounded"}, performance = {rtp = {disabled_plugins = {"gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin"}}}})
end
vim.api.nvim_create_user_command("Nohl", "nohl", {})
local function _40_(opts)
  local width = tonumber(opts.args)
  vim.bo.tabstop = width
  vim.bo.shiftwidth = width
  vim.bo.softtabstop = width
  return nil
end
vim.api.nvim_create_user_command("Tab", _40_, {nargs = 1, desc = "Set tab width for current buffer"})
return nil
