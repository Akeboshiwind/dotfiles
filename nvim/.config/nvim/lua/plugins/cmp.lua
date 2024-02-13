-- plugins/cmp.lua

return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "lukas-reineke/cmp-rg",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        init = function()
            vim.opt.completeopt = { "menu", "menuone", "noselect" }
        end,
        -- NOTE: Intentionally left as a config function instead of opts
        -- This is for a few reasons:
        -- - Ordering really matters in some parts (sources),
        --   - I'd rather keep things explicit
        -- - The config isn't just data, it relies on function calls
        --   - I'd rather not remove them and rely on (potentially) internal details
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            -- >> Setup

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },

                mapping = {
                    ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
                    ["<CR>"] = cmp.mapping.confirm({
                        select = true,
                        behavior = cmp.ConfirmBehavior.Replace,
                    }),
                    ["<C-e>"] = cmp.mapping({
                        i = cmp.mapping.abort(),
                        c = cmp.mapping.close(),
                    }),
                    ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
                    ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),

                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "c" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "c" }),
                },

                sources = cmp.config.sources({
                    { name = "copilot" },
                    { name = "luasnip" },
                    {
                        name = "path",
                        option = {
                            -- trailing_slash = true,
                        },
                    },

                    { name = "conjure" },
                    { name = "nvim_lsp" },

                    {
                        name = "rg",
                        keyword_length = 4,
                    },
                    { name = "buffer" },
                }),
            })

            -- Use buffer source for `/`
            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })

            -- Use cmdline * path source for `:`
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                    { name = "cmdline" },
                }),
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
                mode = "i",
            })
        end,
    },
}
