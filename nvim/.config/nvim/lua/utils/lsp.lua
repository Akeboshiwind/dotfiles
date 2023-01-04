-- utils/lsp.lua

local M = {}

local cmd = vim.cmd

-- >> Setup functions

--- Register Generic LSP mappings
---
--- @param bufnr number
function M.setup_mappings(bufnr)
    local wk = require("which-key")
    local builtin = require("telescope.builtin")

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
            a = { vim.lsp.buf.code_action, "Apply code action" },
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
        mode = "v",
        buffer = bufnr,
    })
end

-- Setup lightbulb to show when there's an action
function M.setup_lightbulb()
    -- TODO: Make buffer local?
    cmd([[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb() ]])
end

-- >> Default LSP config w/ overrides

local lsp_status = require("lsp-status")
-- Already updates based on `vim.lsp.protocol.make_client_capabilities()`
local capabilities = lsp_status.capabilities
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

M.default_config = {
    on_attach = function(client, bufnr)
        -- Status messages
        lsp_status.on_attach(client, bufnr)

        -- Lightbulb
        M.setup_lightbulb()

        -- Mappings
        M.setup_mappings(bufnr)
    end,
    capabilities = capabilities,
}

--- Merges multiple configs together, while composing on_attach functions
---
--- Configs are composed left to right, keeping keys from the rightmost side
--- So `smart_merge_configs({a = 1}, {a = 2})` would get:
--- => `{a = 2}`
--- This is just to make things easier to read, from top to bottom
---
--- `on_attach` functions are composed by running the functions from left to right
--- So `smart_merge_configs(
---       {on_attach = function(client, bufnr) print("a") end},
---       {on_attach = function(client, bufnr) print("b") end})`
--- Effectively produces:
--- => `{on_attach = function(client, bufnr) print("a") print("b") end}`
---
--- @vararg table #Config tables
---
--- @return table #The composed configs
function M.smart_merge_configs(...)
    local configs = { ... }

    -- Composed on_attach functions
    local composed = function(_, _) end

    for _, config in pairs(configs) do
        if config.on_attach then
            local prev_composed = composed
            composed = function(client, bufnr)
                -- Call the previous one first
                -- This runs the `on_attach` functions in
                -- the order they were specified
                prev_composed(client, bufnr)

                config.on_attach(client, bufnr)
            end
        end
    end

    -- Override on_attach w/ composed version
    table.insert(configs, { on_attach = composed })

    return vim.tbl_deep_extend("force", unpack(configs))
end

return M
