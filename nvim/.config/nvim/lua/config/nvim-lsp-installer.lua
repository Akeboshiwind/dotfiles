-- config/nvim-lsp-installer.lua

config = {}
lsp_installer = require('nvim-lsp-installer')


-- >> Utils

-- Updates all installed lsp servers
--
-- Run this when the plugin updates
function config.update_installed()
    local installed = lsp_installer.get_installed_servers()
    for _, server in pairs(installed) do
        server:install()
    end
end

-- Returns the server
--
-- If it doesn't exist, throws an error to the user
function config.get_server(server_name)
    local ok, server = lsp_installer.get_server(server_name)

    if not ok then
        error(string.format("LSP server not found: %s", server_name))
    end

    return server
end

return config
