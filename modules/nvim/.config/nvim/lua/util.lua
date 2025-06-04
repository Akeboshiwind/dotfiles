-- [nfnl] Compiled from lua/util.fnl by https://github.com/Olical/nfnl, do not edit.
local function on_very_lazy(f)
  local function _1_()
    return f()
  end
  return vim.api.nvim_create_autocmd("User", {pattern = "VeryLazy", callback = _1_})
end
local function debounce(ms, f)
  local timer = vim.loop.new_timer()
  local function _2_(...)
    local argv = {...}
    local function _3_()
      timer:stop()
      return vim.schedule_wrap(f)(unpack(argv))
    end
    return timer:start(ms, 0, _3_)
  end
  return _2_
end
local lsp = {}
lsp["on-attach"] = function(on_attach)
  local function _4_(args)
    local buffer = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    return on_attach(client, buffer)
  end
  return vim.api.nvim_create_autocmd("LspAttach", {callback = _4_})
end
return {["on-very-lazy"] = on_very_lazy, debounce = debounce, lsp = lsp}
