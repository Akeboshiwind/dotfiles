-- plugins/lsp/mason.lua
-- TODO: Update packages regularly? Reminder?

return {
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        opts = {
            ensure_installed = { },
            mason_lspconfig = {
                automatic_installation = true,
            },
        },
        config = function(_, opts)
            require("mason").setup(opts)
            require("mason-lspconfig").setup(opts.mason_lspconfig)

            local mr = require("mason-registry")

            local function ensure_installed()
                for _, tool in ipairs(opts.ensure_installed) do
                    local p = mr.get_package(tool)
                    if not p:is_installed() then
                        p:install()
                    end
                end
            end

            mr.refresh(ensure_installed)
        end
    }
}
