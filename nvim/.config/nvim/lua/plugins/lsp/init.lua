-- plugins/lsp/init.lua
local util = require("util")

--- Register Generic LSP mappings
---
--- @param bufnr number
function setup_mappings(bufnr)
    local wk = require("which-key")
    local builtin = require("telescope.builtin")

    -- >> Mappings
    local filetype = vim.bo[bufnr].filetype

    -- Non-Prefixed
    if filetype ~= "clojure" then
        wk.register({
            K = { vim.lsp.buf.hover, "Document symbol" },
        }, {
            buffer = bufnr,
        })
    end

    -- Leader
    wk.register({

        r = {
            name = "run",
            n = { vim.lsp.buf.rename, "Rename symbol under cursor" },
            f = { vim.lsp.buf.formatting, "Format the buffer" },
        },

        a = {
            name = "action",
            a = { vim.lsp.buf.code_action, "Apply code action" },
            -- Add keybind for whole buffer?
        },

        g = {
            name = "goto",
            D = { vim.lsp.buf.declaration, "Declaration" },
            i = { builtin.lsp_implementations, "Implementation" },
            y = { builtin.lsp_type_definitions, "Type definition" },
            r = { builtin.lsp_references, "References" },

            s = { builtin.lsp_document_symbols, "Document Symbols" },
            S = { builtin.lsp_workspace_symbols, "Workspace Symbols" },
        },
    }, {
        prefix = "<leader>",
        buffer = bufnr,
    })

    -- Don't overwrite conjure mapping
    if filetype ~= "clojure" then
        wk.register({
            g = {
                name = "goto",
                d = { builtin.lsp_definitions, "Definition" },
            },
        }, {
            prefix = "<leader>",
            buffer = bufnr,
        })
    end

    -- Visual
    wk.register({
        a = {
            name = "action",
            a = { ":'<,'>Telescope lsp_range_code_actions<CR>", "Apply code action" },
        },
    }, {
        prefix = "<leader>",
        mode = "v",
        buffer = bufnr,
    })
end

return {
    {
        "j-hui/fidget.nvim",
        event = "LspAttach",
        opts = {},
    },
    {
        "nvim-lua/lsp-status.nvim",
        -- Maybe init so this can be lazy?
        config = function()
            util.lsp.on_attach(function(client, bufnr)
                require("lsp-status").on_attach(client, bufnr)
            end)
        end,
    },
    {
        "kosayoda/nvim-lightbulb",
        -- Maybe init so this can be lazy?
        config = function()
            util.lsp.on_attach(function(client, bufnr)
                -- TODO: Make buffer local?
                vim.cmd([[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb() ]])
            end)
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            -- Not sure what needs to be here anymore
            "williamboman/mason.nvim",
            "nvim-lua/lsp-status.nvim",
            "folke/which-key.nvim",
            "nvim-telescope/telescope.nvim",
            "kosayoda/nvim-lightbulb",
            "j-hui/fidget.nvim",
        },
        opts = {
            -- LSP Servers
            servers = {},
            -- Optional setup function for servers
            setup = {},
        },
        config = function(_, opts)
            -- TODO: Allow lsp servers to not use default functionality

            -- TODO: Have some way of the other plugins setting this up
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                require("cmp_nvim_lsp").default_capabilities(),
                require("lsp-status").capabilities,
                opts.capabilities or {}
            )

            util.lsp.on_attach(function(client, bufnr)
                setup_mappings(bufnr)
            end)

            for server, server_opts in pairs(opts.servers) do
                local final_server_opts = vim.tbl_deep_extend("force", {
                    capabilities = vim.deepcopy(capabilities),
                }, server_opts or {})
                if opts.setup[server] then
                    opts.setup[server](server, final_server_opts)
                else
                    require("lspconfig")[server].setup(final_server_opts)
                end
            end
        end,
    },
    { import = "plugins.lsp.mason" },
    { import = "plugins.lsp.null-ls" },
}
