-- config/nvim-compe.lua

local opt = vim.opt
local cmp = require('cmp')
local luasnip = require('luasnip')


-- >> Prerequisites

opt.completeopt = { "menu", "menuone", "noselect" }



-- >> Setup


cmp.setup {
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end
    },

    mapping = {
        ["<C-Space>"] = cmp.mapping(
            cmp.mapping.complete(),
            { 'i', 'c' }
        ),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<C-e>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ["<C-u>"] = cmp.mapping(
            cmp.mapping.scroll_docs(-4),
            { 'i', 'c' }
        ),
        ["<C-d>"] = cmp.mapping(
            cmp.mapping.scroll_docs(4),
            { 'i', 'c' }
        ),

        ["<Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                else
                    fallback()
                end
            end,
            { 'i', 'c' }
        ),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end,
            { 'i', 'c' }
        ),
    },

    sources = cmp.config.sources {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        {
            name = 'rg',
            keyword_length = 3,
        },
        {
            name = 'path',
            option = {
                trailing_slash = true
            },
        },

        { name = 'conjure' },
    },
}

-- Use buffer source for `/`
cmp.setup.cmdline('/', {
    sources = {
        { name = 'buffer' },
    }
})

-- Use cmdline * path source for `:`
cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
        { name = 'path' },
        { name = 'cmdline' },
    })
})



-- >> Mappings

local wk = require("which-key")

wk.register({
    ["<C-Space>"] = "Invoke completion",
    ["<CR>"] = "Confirm selection, or fallback",
    ["<C-e>"] = "Close the completion menu",
    ["<C-u>"] = "Page up",
    ["<C-d>"] = "Page down",

    ["<TAB>"] = "Next completion item",
    ["<S-TAB>"] = "Prev completion item",
}, {
    mode = 'i'
})
