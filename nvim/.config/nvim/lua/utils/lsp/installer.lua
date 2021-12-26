-- utils/lsp/installer.lua

local M = {}

local cmd = vim.cmd
local lsp_installer = require('nvim-lsp-installer')


-- >> Utils

--- Updates all installed lsp servers
---
--- Also opens the info window
---
--- Run this when the plugin updates
--- TODO: Only update plugins that have changed versions?
--- TODO: If so have a `force` parameter
function M.update_installed()
    lsp_installer.info_window.open()
    local installed = lsp_installer.get_installed_servers()
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
function M.get_server(server_name)
    local ok, server = lsp_installer.get_server(server_name)

    if not ok then
        error(string.format("LSP server not found: %s. Maybe misnamed?", server_name))
    end

    return server
end



-- >> Commands

function M.setup_commands()
    cmd [[command! LspUpdateAll lua require('utils.lsp.installer').update_installed()]]
end

return M
