-- [nfnl] lua/plugins/kotlin.fnl
return {{"nvim-neotest/neotest", dependencies = {{"codymikol/neotest-kotlin", branch = "v2.0.0"}}, opts = {adapters = {["neotest-kotlin"] = {}}}}, {"neovim/nvim-lspconfig", opts = {servers = {kotlin_language_server = {enabled = false}, kotlin_lsp = {}}}}}
