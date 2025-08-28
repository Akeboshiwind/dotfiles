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
vim.opt.completeopt = {"menu", "menuone", "noselect"}
local function _2_(args)
  local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
  if client:supports_method("textDocument/completion") then
    vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
  else
  end
  if client:supports_method("textDocument/inlineCompletion") then
    return vim.lsp.inline_completion.enable(true, {client_id = client.id})
  else
    return nil
  end
end
vim.api.nvim_create_autocmd("LspAttach", {callback = _2_})
vim.lsp.config("clojure_lsp", {init_options = {["cljfmt-config-path"] = (vim.fn.stdpath("config") .. "/config/.cljfmt.edn")}})
vim.lsp.config("lua_ls", {settings = {Lua = {diagnostics = {globals = {"vim"}}, workspace = {library = vim.api.nvim_list_runtime_paths()}}}})
vim.keymap.set("i", "<Tab>", "<C-n>")
vim.keymap.set("i", "<S-Tab>", "<C-p>")
vim.keymap.set("i", "<C-l>", vim.lsp.inline_completion.get)
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
  local _let_6_ = require("nfnl.module")
  local autoload = _let_6_["autoload"]
  local lazy_status = autoload("lazy.status")
  local ntn = autoload("nvim-tmux-navigation")
  local telescope = autoload("telescope")
  local telescope_actions = autoload("telescope.actions")
  local telescope_builtin = autoload("telescope.builtin")
  local function _7_()
    local ts = require("nvim-treesitter")
    local available = ts.get_available()
    ts.install({"comment", "regex", "dockerfile", "json", "yaml", "git_config", "git_rebase", "gitattributes", "gitcommit", "gitignore", "bash", "lua", "luadoc", "fennel", "clojure", "java", "javascript", "typescript", "python", "terraform", "html", "nix", "markdown"})
    local function _8_(args)
      local ft = args.match
      local lang = vim.treesitter.language.get_lang(ft)
      if vim.tbl_contains(available, lang) then
        local function _9_()
          return vim.treesitter.start(args.buf, lang)
        end
        ts.install(lang):await(_9_)
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        return nil
      else
        return nil
      end
    end
    return vim.api.nvim_create_autocmd("FileType", {callback = _8_})
  end
  local function _11_()
    local eval = require("conjure.eval")
    return eval.command("(when-let [go! (or (ns-resolve 'user 'go!)\n                                                     (ns-resolve 'user 'go))]\n                                    (go!))")
  end
  local function _12_()
    vim.cmd("w")
    local eval = require("conjure.eval")
    local filename = vim.fn.expand("%:p")
    return eval.command(string.format("(nextjournal.clerk/show! \"%s\")", filename))
  end
  local function _13_(_, opts)
    for k, v in pairs(opts.config) do
      vim.g[string.format("conjure#%s", k)] = v
    end
    return nil
  end
  local function _14_()
    local buffer_relative_path = vim.call("expand", "%:h")
    return telescope.extensions.file_browser.file_browser({cwd = buffer_relative_path})
  end
  local function _15_()
    local buffer_relative_path = vim.call("expand", "%:h")
    return telescope_builtin.live_grep({cwd = buffer_relative_path})
  end
  local function _16_()
    return vim.diagnostic.goto_next({float = {border = "rounded"}})
  end
  local function _17_()
    return vim.diagnostic.goto_prev({float = {border = "rounded"}})
  end
  local function _18_(...)
    return telescope_actions.close(...)
  end
  local function _19_(...)
    return telescope_actions.move_selection_next(...)
  end
  local function _20_(...)
    return telescope_actions.move_selection_previous(...)
  end
  local function _21_(...)
    do local _ = telescope_actions.which_key end
    return ...
  end
  local function _22_(_, opts)
    telescope.setup(opts)
    for name, _0 in pairs(opts.extensions) do
      telescope.load_extension(name)
    end
    return nil
  end
  local function _23_()
    return {["@comment.todo"] = {link = "@comment.note"}}
  end
  local function _24_(_, opts)
    do
      local k = require("kanagawa")
      k.setup(opts)
    end
    return vim.cmd("colorscheme kanagawa")
  end
  local function _25_()
    return ntn.NvimTmuxNavigateLeft()
  end
  local function _26_()
    return ntn.NvimTmuxNavigateDown()
  end
  local function _27_()
    return ntn.NvimTmuxNavigateUp()
  end
  local function _28_()
    return ntn.NvimTmuxNavigateRight()
  end
  lazy.setup({{"Olical/nfnl", ft="fennel"},{"williamboman/mason.nvim", cmd = "Mason", keys = {{"<leader>cm", "<cmd>Mason<cr>", desc = "Mason"}}, opts = {}}, {"williamboman/mason-lspconfig.nvim", dependencies = {"williamboman/mason.nvim", "neovim/nvim-lspconfig"}, opts = {ensure_installed = {"clojure_lsp", "fennel_language_server", "pyright", "rust_analyzer", "terraformls", "ts_ls", "copilot", "kotlin_lsp"}, automatic_enable = true}}, {"nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate", config = _7_, lazy = false}, {"Olical/conjure", ft = {"clojure", "fennel", "python"}, keys = {{"<leader>eg", _11_, desc = "user/go!"}, {"<leader>es", _12_, desc = "clerk/show!"}}, opts = {config = {["mapping#prefix"] = "<leader>", ["client#clojure#nrepl#refresh#backend"] = "clj-reload", ["highlight#enabled"] = true, ["client#clojure#nrepl#connection#auto_repl#enabled"] = false, ["client#clojure#nrepl#mapping#session_select"] = false}}, config = _13_}, {"nvim-telescope/telescope.nvim", dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzf-native.nvim", "nvim-telescope/telescope-ui-select.nvim", "nvim-telescope/telescope-file-browser.nvim"}, keys = {{"<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files"}, {"<leader>fr", _14_, desc = "Browse relative to buffer"}, {"<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags"}, {"<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers"}, {"<leader>ss", "<cmd>Telescope live_grep<CR>", desc = "Search project file contents"}, {"<leader>sr", _15_}, {"<leader>dn", _16_, desc = "Next"}, {"<leader>dp", _17_, desc = "Previous"}}, opts = {defaults = {mappings = {i = {["<esc>"] = _18_, ["<C-j>"] = _19_, ["<C-k>"] = _20_, ["<C-h>"] = _21_}}}, extensions = {fzf = {}, ["ui-select"] = {}, file_browser = {}}}, config = _22_}, {"rebelot/kanagawa.nvim", priority = 1000, opts = {dimInactive = true, overrides = _23_}, config = _24_}, {"nvim-lualine/lualine.nvim", dependencies = {"kyazdani42/nvim-web-devicons"}, opts = {sections = {lualine_a = {"filename"}, lualine_b = {"branch", "diff", "diagnostics"}, lualine_c = {"searchcount"}, lualine_x = {{lazy_status.updates, cond = lazy_status.has_updates, color = {fg = "#ff9e64"}}}, lualine_y = {}, lualine_z = {"location"}}}}, "tpope/vim-fugitive", "arp242/auto_mkdir2.vim", {"alexghergh/nvim-tmux-navigation", opts = {}, keys = {{"<C-h>", _25_, desc = "Navigate Left"}, {"<C-j>", _26_, desc = "Navigate Left"}, {"<C-k>", _27_, desc = "Navigate Left"}, {"<C-l>", _28_, desc = "Navigate Left"}}}, {"folke/which-key.nvim", event = "VeryLazy", keys = {{"fd", "<ESC>", desc = "Quick Escape", mode = "i"}}, opts = {notify = false}}}, {ui = {border = "rounded"}, performance = {rtp = {disabled_plugins = {"gzip", "matchit", "matchparen", "netrwPlugin", "tarPlugin", "tohtml", "tutor", "zipPlugin"}}}})
end
vim.api.nvim_create_user_command("Nohl", "nohl", {})
local function _29_(opts)
  local width = tonumber(opts.args)
  vim.bo.tabstop = width
  vim.bo.shiftwidth = width
  vim.bo.softtabstop = width
  return nil
end
vim.api.nvim_create_user_command("Tab", _29_, {nargs = 1, desc = "Set tab width for current buffer"})
return nil
