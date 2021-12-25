-- utils/lsp/config.lua

local M = {}


-- >> Setup functions

--- Register Generic LSP mappings
---
--- @param bufnr number
function M.setup_mappings(bufnr)
    local wk = require("which-key")
    local builtin = require('telescope.builtin')


    -- >> Mappings

    -- Non-Prefixed
    wk.register({
        K = { vim.lsp.buf.hover, "Document symbol" },
    }, {
        buffer = bufnr,
    })

    -- Leader
    wk.register({

        r = {
            name = "run",
            n = { vim.lsp.buf.rename, "Rename symbol under cursor" },
            f = { vim.lsp.buf.formatting, "Format the buffer" },
        },

        a = {
            name = "action",
            a = { builtin.lsp_code_actions, "Apply code action" },
            -- Add keybind for whole buffer?
        },

        g = {
            name = "goto",
            D = { vim.lsp.buf.declaration, "Declaration" },
            d = { builtin.lsp_definitions, "Definition" },
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

    -- Visual
    wk.register({
        a = {
            name = "action",
            a = { ":'<,'>Telescope lsp_range_code_actions<CR>", "Apply code action" },
        },
    }, {
        prefix = "<leader>",
        mode = 'v',
        buffer = bufnr,
    })
end



-- >> Default LSP config w/ overrides

local lsp_status = require('lsp-status')

local default_config = {
    on_attach = function(client, bufnr)
        -- Status messages
        lsp_status.on_attach(client, bufnr)

        -- Mappings
        M.setup_mappings(bufnr)
    end,
    capabilities = lsp_status.capabilities,
}

--- Compose together multiple configs
---
--- Configs are composed in reverse order
--- So `compose_config({a = 1}, {a = 2})` would get:
--- => `{a = 1}`
---
--- A default_config is always used as the base to compose the other configs
--- onto
---
--- The first config supplied is assumed to be the user_config
---
--- When composing the default_config with the user_config the on_attach
--- functions are combined so that the default on_attach is run, and then the
--- user on_attach
---
--- @vararg table #Config tables
---
--- @return table #The composed configs
function M.compose_config(...)
    local configs = {...}

    -- Compose together the on_attach functions
    local override = {}
    if #configs >= 1 and configs[1].on_attach then
        local user_on_attach = configs[1].on_attach
        override.on_attach = function(client, bufnr)
            default_config.on_attach(client, bufnr)

            -- We use the user one after so we can override things
            user_on_attach(client, bufnr)
        end
    end

    -- Use default_config as base
    table.insert(configs, 1, default_config)
    -- Override usef config
    table.insert(configs, override)

    return vim.tbl_deep_extend("force", unpack(configs))
end



return M
