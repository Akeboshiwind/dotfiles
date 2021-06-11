-- config/nvim-lspconfig.lua

local lsp = {}


-- >> Generic keybinds for lsp servers

function lsp.setup_mappings()
    local wk = require("which-key")
    local builtin = require('telescope.builtin')


    -- >> Mappings

    -- Docs
    wk.register({
        -- TODO: Will this actually overwrite the top level symbol?
        K = { vim.lsp.buf.hover, "Document symbol" },
    }, {
        -- Buffer local mappings
        buffer = 0,
    })

    -- leader mappings
    wk.register({
        -- TODO: Other useful lsp mappings?
        -- TODO: Telescope mappings?
        -- TODO: Better mnumonics?

        -- TODO: Change gotos to non-prefixed?
        g = {
            name = "goto",
            D = { vim.lsp.buf.declaration, "Declaration" },
            d = { builtin.lsp_definitions, "Definition" },
            i = { builtin.implementations, "Implementation" },
            y = { vim.lsp.buf.type_definition, "Type definition" },
            r = { builtin.lsp_references, "References" },

            -- Are these `find` related?
            s = { builtin.lsp_document_symbols, "Document Symbols" },
            --S = { builtin.lsp_workspace_symbols, "Workspace Symbols" },
            --S = { builtin.lsp_dynamic_workspace_symbols, "Workspace Symbols" },
        },

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
            d = { builtin.lsp_document_diagnostics, "Show document diagnostics" },
            D = { builtin.lsp_workspace_diagnostics, "Show workspace diagnostics" },
            -- Make these [d & ]d ?
            n = { vim.lsp.diagnostic.goto_next, "Next" },
            p = { vim.lsp.diagnostic.goto_prev, "Previous" },
        },

        -- buf_set_keymap('n', '<space>q',
        --                '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>',
        --                opts)
    }, {
        prefix = "<leader>",
        -- Buffer local mappings
        buffer = 0,
    })

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
        buffer = 0,
    })
end

return lsp
