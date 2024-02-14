-- [nfnl] Compiled from fnl/plugins/lang/clojure.fnl by https://github.com/Olical/nfnl, do not edit.
local function _1_()
  local g = vim.g
  g["conjure#mapping#prefix"] = "<leader>"
  g["conjure#highlight#enabled"] = true
  g["conjure#filetypes"] = {"clojure"}
  g["conjure#client#clojure#nrepl#mapping#session_select"] = false
  g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = false
  return nil
end
local function _2_()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = (require("telescope.config")).values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local function shadow_select(opts)
    local opts0 = (opts or {})
    local entry_cache = {}
    local function _3_(entry)
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
    opts0.entry_maker = _3_
    local function _6_(_2410)
      local function _7_(prompt_bufnr, _)
        local function _8_()
          actions.close(prompt_bufnr)
          do
            local selection = action_state.get_selected_entry()
            local app = selection.value
            vim.cmd(string.format("ConjureShadowSelect %s", app))
          end
          return true
        end
        return (actions.select_default):replace(_8_)
      end
      return (_2410).new(opts0, {prompt_title = "shadow-cljs apps", finder = finders.new_oneshot_job({"ps", "aux"}, opts0), sorter = conf.generic_sorter(opts0), attach_mappings = _7_})
    end
    return _6_(pickers):find()
  end
  local wk = require("which-key")
  local function _9_()
    vim.cmd("w")
    local filename = vim.fn.expand("%:p")
    return vim.cmd(string.format("ConjureEval (nextjournal.clerk/show! \"%s\")", filename))
  end
  return wk.register({e = {g = {":ConjureEval (user/go!)<CR>", "user/go!"}, s = {_9_, "clerk/show!"}}, s = {S = {shadow_select, "Conjure Select Shadowcljs Environment"}}}, {prefix = "<leader>"})
end
return {{"neovim/nvim-lspconfig", opts = {servers = {clojure_lsp = {init_options = {["cljfmt-config-path"] = (vim.fn.stdpath("config") .. "/config/.cljfmt.edn")}}}}}, {"PaterJason/cmp-conjure", dependencies = {"hrsh7th/nvim-cmp"}}, {"eraserhd/parinfer-rust", build = "cargo build --release"}, {"folke/which-key.nvim", opts = {defaults = {["<leader>l"] = {name = "log"}, ["<leader>e"] = {name = "eval"}, ["<leader>c"] = {name = "display as comment"}, ["<leader>g"] = {name = "goto"}, ["<leader>G"] = {name = "git"}, ["<leader>v"] = {name = "view"}, ["<leader>s"] = {name = "session"}, ["<leader>t"] = {name = "test"}, ["<leader>r"] = {name = "refresh"}}}}, {"Olical/conjure", tag = "v4.50.0", dependencies = {"nvim-telescope/telescope.nvim", "eraserhd/parinfer-rust", "PaterJason/cmp-conjure"}, init = _1_, config = _2_}}
