-- [nfnl] Compiled from fnl/plugins/lang/clojure.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_(_, opts)
  for k, v in pairs(opts.config) do
    vim.g[string.format("conjure#%s", k)] = v
  end
  do
    local pickers = require("telescope.pickers")
    require("telescope.finders")
    do local _ = (require("telescope.config")).values end
    require("telescope.actions")
    require("telescope.actions.state")
  end
  local function shadow_select(opts0)
    local opts1 = (opts0 or {})
    local entry_cache = {}
    local function _2_(entry)
      local app = entry:match("shadow[-]cljs watch (%w*)")
      if app then
        if not entry_cache[app] then
          entry_cache[app] = true
          return {value = app, display = app, ordinal = app}
        else
          return nil
        end
      else
        return nil
      end
    end
    opts1.entry_maker = _2_
    local function _5_(_241)
      local function _6_(prompt_bufnr, _0)
        local function _7_()
          actions.close(prompt_bufnr)
          do
            local selection = action_state.get_selected_entry()
            local app = selection.value
            vim.cmd(string.format("ConjureShadowSelect %s", app))
          end
          return true
        end
        return (actions.select_default):replace(_7_)
      end
      return (_241).new(opts1, {prompt_title = "shadow-cljs apps", finder = finders.new_oneshot_job({"ps", "aux"}, opts1), sorter = conf.generic_sorter(opts1), attach_mappings = _6_})
    end
    return _5_(pickers):find()
  end
  local wk = require("which-key")
  local function _8_()
    vim.cmd("w")
    local filename = vim.fn.expand("%:p")
    return vim.cmd(string.format("ConjureEval (nextjournal.clerk/show! \"%s\")", filename))
  end
  return wk.register({e = {g = {":ConjureEval (user/go!)<CR>", "user/go!"}, s = {_8_, "clerk/show!"}}, s = {S = {shadow_select, "Conjure Select Shadowcljs Environment"}}}, {prefix = "<leader>"})
end
return {{"neovim/nvim-lspconfig", opts = {servers = {clojure_lsp = {init_options = {["cljfmt-config-path"] = (vim.fn.stdpath("config") .. "/config/.cljfmt.edn")}}}}}, {"PaterJason/cmp-conjure", dependencies = {"hrsh7th/nvim-cmp"}}, {"eraserhd/parinfer-rust", build = "cargo build --release"}, {"folke/which-key.nvim", opts = {defaults = {["<leader>l"] = {name = "log"}, ["<leader>e"] = {name = "eval"}, ["<leader>c"] = {name = "display as comment"}, ["<leader>g"] = {name = "goto"}, ["<leader>G"] = {name = "git"}, ["<leader>v"] = {name = "view"}, ["<leader>s"] = {name = "session"}, ["<leader>t"] = {name = "test"}, ["<leader>r"] = {name = "refresh"}}}}, {"Olical/conjure", tag = "v4.50.0", dependencies = {"nvim-telescope/telescope.nvim", "eraserhd/parinfer-rust", "PaterJason/cmp-conjure"}, opts = {config = {["mapping#prefix"] = "<leader>", ["highlight#enabled"] = true, filetypes = {"clojure"}, ["client#clojure#nrepl#mapping#session_select"] = false, ["client#clojure#nrepl#connection#auto_repl#enabled"] = false}}, config = _1_}}
