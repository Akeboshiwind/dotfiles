-- [nfnl] lua/plugins/lang/python.fnl
return {{["mason/ensure-installed"] = {"black", "isort"}, ["format/by-ft"] = {python = {"black", "isort"}}, ["lsp/servers"] = {pylsp = {}}}}
