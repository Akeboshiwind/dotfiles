-- [nfnl] lua/plugins/lang/lua.fnl
return {{["mason/ensure-installed"] = {"stylua"}, ["format/by-ft"] = {lua = {"stylua"}}, ["format/formatters"] = {stylua = {prepend_args = {"--config-path", (vim.fn.stdpath("config") .. "/config/stylua.toml")}}}}}
