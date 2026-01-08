-- [nfnl] lua/plugins/kotlin.fnl
return {{"nvim-neotest/neotest", dependencies = {{"ake-forks/neotest-kotlin", branch = "v2.0.0-backticks-fix"}}, opts = {adapters = {["neotest-kotlin"] = {}}}}, {"neovim/nvim-lspconfig", opts = {servers = {kotlin_language_server = {enabled = false}, kotlin_lsp = {}}}}}
