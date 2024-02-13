-- plugins/lsp/mason.lua
-- TODO: Update packages regularly? Reminder?

return {
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        -- TODO: Why can't this just be specifying a map?
        -- list-like tables seem to not merge well w/ lazy.nvim
        -- TODO: One way to get rid of this would be to make ensure_installed a map like so:
        -- { black = true, stylua = true }
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            opts.mason_lspconfig = opts.mason_lspconfig
                or {
                    automatic_installation = true,
                }
        end,
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
        end,
    },
}
