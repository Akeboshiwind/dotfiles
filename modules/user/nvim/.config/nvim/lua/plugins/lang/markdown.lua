-- [nfnl] lua/plugins/lang/markdown.fnl
return {{"davidmh/mdx.nvim", dependencies = {"nvim-treesitter"}, config = true}, {"kevinhwang91/nvim-ufo", opts = {["close-kinds"] = {markdown = {"section", "fenced_code_block"}}}}}
