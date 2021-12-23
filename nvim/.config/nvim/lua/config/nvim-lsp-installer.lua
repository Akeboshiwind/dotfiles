-- config/nvim-lsp-installer.lua

local config = {}

local cmd = vim.cmd


-- >> Utils

--- Updates all installed lsp servers
---
--- Run this when the plugin updates
--- TODO: Only update plugins that have changed versions?
--- TODO: If so have a `force` parameter
function config.update_installed()
    local installed = require('nvim-lsp-installer').get_installed_servers()
    for _, server in pairs(installed) do
        server:install()
    end
end

--- Returns the server
---
--- If it doesn't exist, throws an error to the user
---
--- @param server_name string #The name of the server to search for
---
--- @return Server #The name of the server to search for
function config.get_server(server_name)
    local ok, server = require('nvim-lsp-installer').get_server(server_name)

    if not ok then
        error(string.format("LSP server not found: %s. Maybe misnamed?", server_name))
    end

    return server
end



-- >> Commands

function config.setup_commands()
    cmd [[command! LspUpdateAll lua require('config.nvim-lsp-installer').update_installed()]]
end

return config
