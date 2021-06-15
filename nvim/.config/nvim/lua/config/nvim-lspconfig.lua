-- config/nvim-lspconfig.lua

local lsp = {}

local fn = vim.fn
local cmd = vim.cmd


-- >> Setup functions

-- Register Generig LSP mappings
--
-- @param bufnr number
function lsp.setup_mappings(bufnr)
    local wk = require("which-key")
    local builtin = require('telescope.builtin')


    -- >> Mappings

    -- Non-Prefixed
    wk.register({
        K = { vim.lsp.buf.hover, "Document symbol" },
        g = {
            name = "goto",
            D = { vim.lsp.buf.declaration, "Declaration" },
            d = { ":TroubleToggle lsp_definitions<CR>", "Definition" },
            i = { builtin.implementations, "Implementation" },
            y = { vim.lsp.buf.type_definition, "Type definition" },
            r = { ":TroubleToggle lsp_references<CR>", "References" },

            s = { builtin.lsp_document_symbols, "Document Symbols" },
            S = { builtin.lsp_workspace_symbols, "Workspace Symbols" },

            q = { ":TroubleToggle quickfix<cr>", "Quickfix list" },
        },
    }, {
        buffer = bufnr,
    })

    -- Leader
    wk.register({
        -- TODO: Other useful lsp mappings?
        -- TODO: Better mnumonics?
        -- TODO: Convert some functions into telescope functions
        --       - List workspace folders

        w = {
            name = "workspace",
            a = { vim.lsp.buf.add_workspace_folder, "Add workspace folder" },
            r = { vim.lsp.buf.remove_workspace_folder,
                  "Remove workspace folder" },
            l = { vim.lsp.buf.list_workspace_folders,
                  "List workspace folders" },
        },

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

        d = {
            name = "diagnostics",
            d = { ":TroubleToggle lsp_document_diagnostics<cr>",
                  "Show document diagnostics" },
            D = { ":TroubleToggle lsp_workspace_diagnostics<cr>",
                  "Show workspace diagnostics" },
            -- Make these [d & ]d ?
            n = { vim.lsp.diagnostic.goto_next, "Next" },
            p = { vim.lsp.diagnostic.goto_prev, "Previous" },
        },

        -- buf_set_keymap('n', '<space>q',
        --                '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>',
        --                opts)
    }, {
        prefix = "<leader>",
        buffer = bufnr,
    })

    -- Visual
    wk.register({
        a = {
            name = "action",
            -- TODO: Why do you have to press <esc> after running?
            -- TODO: Does this select the wrong range?
            -- TODO: Does it pass the right range to the `extract to function`?
            a = { builtin.lsp_range_code_actions, "Apply code action" },
        },
    }, {
        prefix = "<leader>",
        mode = 'v',
        buffer = bufnr,
    })
end

-- Setup lsp gutter signs
function lsp.setup_signs()
    local sign_config = {
        LspDiagnosticsSignError = '',
        LspDiagnosticsSignWarning = '',
        LspDiagnosticsSignInformation = '',
        LspDiagnosticsSignHint = '',
    }

    for sign, symbol in pairs(sign_config) do
        fn.sign_define(sign, {
            text = symbol,
            texthl = sign,
            linehl = '',
            numhl = '',
        })
    end
end

-- Setup lighbulb to show when there's an action
function lsp.setup_lightbulb()
    -- TODO: Make buffer local?
    cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb() ]]
end



-- >> Default LSP config w/ overrides

local lsp_status = require('lsp-status')

local default_config = {
    on_attach = function(client, bufnr)
        -- Status messages
        lsp_status.on_attach(client, bufnr)

        -- Setup
        lsp.setup_mappings(bufnr)
        lsp.setup_signs()
        lsp.setup_lightbulb()
        require'lsp_signature'.on_attach()
    end,
    capabilities = lsp_status.capabilities,
}

-- Compose together multiple configs
--
-- Configs are composed in reverse order
-- So `compose_config({a = 1}, {a = 2})` would get:
-- => `{a = 1}`
--
-- A default_config is always used as the base to compose the other configs
-- onto
--
-- The first config supplied is assumed to be the user_config
--
-- When composing the default_config with the user_config the on_attach
-- functions are combined so that the default on_attach is run, and then the
-- user on_attach
--
-- @vararg table       - Config tables
--
-- @return table       - The composed configs
function lsp.compose_config(...)
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

    return vim.tbl_deep_extend("force",
        default_config,
        unpack(configs),
        override)
end



return lsp
