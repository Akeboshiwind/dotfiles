-- [nfnl] lua/plugins/fennel.fnl
return {{"Olical/nfnl", ft = "fennel"}, {"nvim-treesitter/nvim-treesitter", opts = {ensure_installed = {"fennel"}}}, {"neovim/nvim-lspconfig", opts = {servers = {fennel_language_server = {settings = {fennel = {diagnostics = {globals = {"vim"}}}}}}}}}
