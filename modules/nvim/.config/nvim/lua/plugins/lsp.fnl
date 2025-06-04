; plugins/lsp.fnl
(local {: autoload} (require :nfnl.module))
(local util (autoload :util))
(local wk (autoload :which-key))
(local builtin (autoload :telescope.builtin))
(local lspconfig (autoload :lspconfig))
(local lsp-ui-window (autoload :lspconfig.ui.windows))
(local nvim-lightbulb (autoload :nvim-lightbulb))
(local cmp-nvim-lsp (autoload :cmp_nvim_lsp))

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
  :opts {; LSP Servers
         ; Put the lsp server (following the nvim-lspconfig naming)
         ; along with any associated config
         :servers {}
         ; (optional) Override setup function for lsp server
         ; Defaults to lspconfig setup function
         :setup {}}
  :config (fn [_ opts]
            (set lsp-ui-window.default_options {:border "rounded"})

            (util.lsp.on-attach
              (fn [_client bufnr]
                (setup-mappings bufnr)))

            ; TODO: Allow lsp servers to not use default functionality
            ; TODO: Have some way of the other plugins setting this up
            (let [capabilities (vim.tbl_deep_extend "force"
                                 {}
                                 (vim.lsp.protocol.make_client_capabilities)
                                 (cmp-nvim-lsp.default_capabilities)
                                 (or opts.capabilities {}))]
              (each [server server-opts (pairs opts.servers)]
                (let [final-server-opts
                      (vim.tbl_deep_extend "force"
                        {:capabilities (vim.deepcopy capabilities)}
                        (or server-opts {}))]
                  (if (. opts :setup server)
                    ((. opts :setup server) server final-server-opts)
                    ((. lspconfig server :setup) final-server-opts))))))}]
