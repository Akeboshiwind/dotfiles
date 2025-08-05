; plugins/lsp.fnl
(local {: autoload} (require :nfnl.module))
(local util (autoload :util))
(local wk (autoload :which-key))
(local builtin (autoload :telescope.builtin))
(local nvim-lightbulb (autoload :nvim-lightbulb))
(local cmp-nvim-lsp (autoload :cmp_nvim_lsp))
(local cfg (autoload :util.cfg))

; Register Generic LSP mapings
(fn setup-mappings [bufnr]
  (let [filetype (. vim :bo bufnr :filetype)]

    ; >> Non-prefixed
    (if (not= filetype "clojure")
      (wk.add
        [{1 "K" 2 vim.lsp.buf.hover :desc "Document symbol" :buffer bufnr}]))

    ; >> Leader
    (wk.add
      {:buffer bufnr
       1 [{1 "<leader>r" :group "run"}
          {1 "<leader>rn" 2 vim.lsp.buf.rename :desc "Rename symbol under cursor"}
               ;; TODO: Remove?
          {1 "<leader>rf" 2 vim.lsp.buf.formatting :desc "Format the buffer"}
          {1 "<leader>a" :group "action"}
          {1 "<leader>aa" 2 vim.lsp.buf.code_action :desc "Apply code action"}
          {1 "<leader>g" :group "goto"}
          {1 "<leader>gD" 2 vim.lsp.buf.declaration :desc "Declaration"}
          {1 "<leader>gi" 2 builtin.lsp_implementations :desc "Implementation"} 
          {1 "<leader>gy" 2 builtin.lsp_type_definitions :desc "Type definition"} 
          {1 "<leader>gr" 2 builtin.lsp_references :desc "References"} 
          {1 "<leader>gs" 2 builtin.lsp_document_symbols :desc "Document Symbols"} 
          {1 "<leader>gS" 2 builtin.lsp_workspace_symbols :desc "Workspace Symbols"}]}) 

    ; Don't overwrite conjure mapping
    (if (not= filetype "clojure")
      (wk.add
        {:buffer bufnr
         1 [{1 "<leader>gd" 2 builtin.lsp_definitions :desc "Definition"}]}))

    ; Visual
    (wk.add
      {:mode :v
       :buffer bufnr
       1 [{1 "<leader>a" :group "action"}
          {1 "<leader>aa" 2 ":'<,'>Telescope lsp_range_code_actions<CR>" :desc "Apply code action"}]})))

[{1 :j-hui/fidget.nvim
  :event :LspAttach
  :opts {}}
 {1 :kosayoda/nvim-lightbulb
  :init #(util.lsp.on-attach
           (fn [_client bufnr]
             (vim.api.nvim_create_autocmd ["CursorHold" "CursorHoldI"]
               {:buffer bufnr
                :callback #(nvim-lightbulb.update_lightbulb)})))}
 {1 :neovim/nvim-lspconfig
  :dependencies [:williamboman/mason-lspconfig.nvim
                 :folke/which-key.nvim
                 :nvim-telescope/telescope.nvim]
  ; >> lsp/servers server-name->opts
  ; Put the lsp server (following the nvim-lspconfig naming)
  ; along with any associated config
  :lsp/servers {}
  :config (fn [_ _ G]
            (util.lsp.on-attach
              (fn [_client bufnr]
                (setup-mappings bufnr)))

            (vim.lsp.config :*
              {:capabilities (vim.tbl_deep_extend "force"
                               {}
                               (vim.lsp.protocol.make_client_capabilities)
                               (cmp-nvim-lsp.default_capabilities)
                               (cfg.merge-all (or G.lsp/capabilities [])))})

            (each [server server-opts (pairs (cfg.merge-all G.lsp/servers))]
              (vim.lsp.config server (or server-opts {}))))}]
