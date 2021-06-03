" post-install.vim


" >> Setup

lua << EOF

require'compe'.setup {
  enabled = true,
  documentation = true,

  source = {
    path = true,
    buffer = true,
    calc = true,
    emoji = true,
    nvim_lsp = true,
    nvim_lua = true,
  },
}

EOF



" >> Mappings

lua << EOF

local wk = require("which-key")

wk.register({
    ["<C-Space>"] = { "compe#complete()", "Invoke completion" },
    ["<CR>"] = { "compe#confirm('<CR>')", "Confirm selection, or fallback" },
    ["<C-e>"] = { "compe#close('<C-e>')", "Close the completion menu" },
    ["<C-u>"] = { "compe#scroll({ delta = 4 })", "Page up" },
    ["<C-d>"] = { "compe#scroll({ delta = -4 })", "Page down" },

    -- NOTE: If I need to do more with my tabs, see nvim-compe repo for example
    ["<TAB>"] = { [[pumvisible() ? "\<C-n>" : "\<TAB>"]], "Next completion item" },
    ["<S-TAB>"] = { [[pumvisible() ? "\<C-p>" : "\<S-TAB>"]],
                    "Prev completion item" }
}, { mode = 'i', expr = true })

EOF
