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
      (wk.register
        {:K [vim.lsp.buf.hover "Document symbol"]}
        {:buffer bufnr}))

    ; >> Leader
    (wk.register
      {:r {:name "run"
           :n [vim.lsp.buf.rename "Rename symbol under cursor"]
           ;; TODO: Remove?
           :f [vim.lsp.buf.formatting "Format the buffer"]}
       :a {:name "action"
           :a [vim.lsp.buf.code_action "Apply code action"]}
       :g {:name "goto"
           :D [vim.lsp.buf.declaration "Declaration"]
           :i [builtin.lsp_implementations "Implementation"] 
           :y [builtin.lsp_type_definitions "Type definition"] 
           :r [builtin.lsp_references "References"] 

           :s [builtin.lsp_document_symbols "Document Symbols"] 
           :S [builtin.lsp_workspace_symbols "Workspace Symbols"]}} 
      {:prefix "<leader>"
       :buffer bufnr})

    ; Don't overwrite conjure mapping
    (if (not= filetype "clojure")
      (wk.register
        {:g {:name "goto"
             :d [builtin.lsp_definitions "Definition"]}}
        {:prefix "<leader>"
         :buffer bufnr}))

    ; Visual
    (wk.register
      {:a {:name "action"
           :a [":'<,'>Telescope lsp_range_code_actions<CR>" "Apply code action"]}}
      {:prefix "<leader>"
       :mode :v
       :buffer bufnr})))

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
  :dependencies [; Not sure what needs to be here anymore
                 :williamboman/mason.nvim
                 :folke/which-key.nvim
                 :nvim-telescope/telescope.nvim
                 :kosayoda/nvim-lightbulb
                 :j-hui/fidget.nvim]
  :opts {; LSP Servers
         :servers {}
         ; Optional setup function for servers
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
