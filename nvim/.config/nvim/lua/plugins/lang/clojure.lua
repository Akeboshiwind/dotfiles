-- [nfnl] Compiled from lua/plugins/lang/clojure.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local _local_2_ = autoload("nfnl.core")
local assoc = _local_2_["assoc"]
local pickers = autoload("telescope.pickers")
local finders = autoload("telescope.finders")
local config = autoload("telescope.config")
local actions = autoload("telescope.actions")
local action_state = autoload("telescope.actions.state")
local eval = autoload("conjure.eval")
local Set = autoload("util.set")
local function make_shadow_entry_maker()
  local entry_cache = Set.new()
  local function _3_(entry)
    local app = entry:match("shadow[-]cljs watch (%w*)")
    if (app and not Set["contains?"](entry_cache, app)) then
      Set["insert!"](entry_cache, app)
      return {value = app, display = app, ordinal = app}
    else
      return nil
    end
  end
  return _3_
end
local function shadow_select(opts)
  local opts0 = assoc((opts or {}), "entry_maker", make_shadow_entry_maker())
  local picker
  local function _5_(prompt_bufnr, _)
    local function _6_()
      actions.close(prompt_bufnr)
      do
        local selection = action_state.get_selected_entry()
        local app = selection.value
        vim.cmd(string.format("ConjureShadowSelect %s", app))
      end
      return true
    end
    return (actions.select_default):replace(_6_)
  end
  picker = pickers.new(opts0, {prompt_title = "shadow-cljs apps", finder = finders.new_oneshot_job({"ps", "aux"}, opts0), sorter = config.values.generic_sorter(opts0), attach_mappings = _5_})
  return picker:find()
end
local function _7_()
  return eval.command("(when-let [go! (or (ns-resolve 'user 'go!)\n                                   (ns-resolve 'user 'go))]\n                  (go!))")
end
local function _8_()
  vim.cmd("w")
  local filename = vim.fn.expand("%:p")
  return eval.command(string.format("(nextjournal.clerk/show! \"%s\")", filename))
end
return {{"neovim/nvim-lspconfig", opts = {servers = {clojure_lsp = {init_options = {["cljfmt-config-path"] = (vim.fn.stdpath("config") .. "/config/.cljfmt.edn")}}}}}, {"eraserhd/parinfer-rust", build = "cargo build --release"}, {"folke/which-key.nvim", opts = {defaults = {["<leader>G"] = {name = "git"}, ["<leader>v"] = {name = "view"}, ["<leader>s"] = {name = "session"}, ["<leader>t"] = {name = "test"}, ["<leader>r"] = {name = "refresh"}}}}, {"Olical/conjure", ft = {"clojure"}, keys = {{"<leader>eg", _7_, desc = "user/go!"}, {"<leader>es", _8_, desc = "clerk/show!"}, {"<leader>sS", shadow_select, desc = "Conjure Select Shadowcljs Environment"}}, opts = {config = {["client#clojure#nrepl#mapping#session_select"] = false, ["client#clojure#nrepl#connection#auto_repl#enabled"] = false}}}}
