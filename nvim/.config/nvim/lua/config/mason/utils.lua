-- config/mason/utils.lua

local M = {}

function M.install_tools(tools)
    local mr = require("mason-registry")
    for _, tool in ipairs(tools) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
            p:install()
        end
    end
end

return M
