-- config/python-tools.lua

local lsp_installer = require('utils.lsp.installer')
local lsp_config = require('utils.lsp.config')


-- >> Install server

local server = lsp_installer.get_server("pylsp")

local was_installed = server:is_installed()
if not was_installed then
    print("Installing LSP server")
    server:install()
end



-- >> Setup

server:on_ready(function ()
    server:setup(lsp_config.smart_merge_configs(
        lsp_config.default_config,
        {
            on_attach = function(_, _)
                -- >> Install plugins

                -- We can't just call the command because it's not setup yet
                -- I think it's ok to reach into the internals a bit here
                -- because this bit _shouldn't_ change :/
                -- Although the name of the command might change :/
                if not was_installed then
                    local default_options = server:get_default_options()
                    local PylspInstall = default_options.commands.PylspInstall[1]

                    PylspInstall(
                        "python-lsp-black",
                        "pylsp-rope"
                    )
                end

                -- >> Format on save

                vim.cmd [[ autocmd BufWritePre *.py lua vim.lsp.buf.formatting_sync(nil, 1000) ]]
            end,
        },
        server:get_default_options()
    ))
end)
