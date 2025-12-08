-- [nfnl] lua/plugins/clojure.fnl
return {{"nvim-paredit/nvim-paredit", enabled = false}, {"eraserhd/parinfer-rust", build = "cargo build --release"}, {"neovim/nvim-lspconfig", opts = {servers = {clojure_lsp = {root_markers = {"deps.edn", "build.boot", "shadow-cljs.edn", ".git", "bb.edn"}}}}}}
