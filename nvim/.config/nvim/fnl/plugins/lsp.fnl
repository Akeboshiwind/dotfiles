; plugins/lsp.fnl
(local util (require "util"))

; Register Generic LSP mapings
(fn setup-mappings [bufnr]
  (let [wk (require "which-key")
        builtin (require "telescope.builtin")
        filetype (. vim :bo bufnr :filetype)]

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
 {1 :nvim-lua/lsp-status.nvim
  ; Maybe init so this can be lazy?
  :config #(util.lsp.on_attach (. (require "lsp-status") :on_attach))}
 {1 :kosayoda/nvim-lightbulb
  ; Maybe init so this can be lazy?
  :config #(util.lsp.on_attach
             (fn [client bufnr]
               ; TODO: Make buffer local?
               (vim.cmd "autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()")))}
 {1 :neovim/nvim-lspconfig
  :dependencies [; Not sure what needs to be here anymore
                 :williamboman/mason.nvim
                 :nvim-lua/lsp-status.nvim
                 :folke/which-key.nvim
                 :nvim-telescope/telescope.nvim
                 :kosayoda/nvim-lightbulb
                 :j-hui/fidget.nvim]
  :opts {; LSP Servers
         :servers {}
         ; Optional setup function for servers
         :setup {}}
  :config (fn [_ opts]
            (tset (require "lspconfig.ui.windows") :default_options
             {:border "rounded"})

            (util.lsp.on_attach
              (fn [client bufnr]
                (setup_mappings bufnr)))

            ; TODO: Allow lsp servers to not use default functionality
            ; TODO: Have some way of the other plugins setting this up
            (let [capabilities (vim.tbl_deep_extend "force"
                                 {}
                                 (vim.lsp.protocol.make_client_capabilities)
                                 ((. (require "cmp_nvim_lsp") :default_capabilities))
                                 (. (require "lsp-status") :capabilities)
                                 (or opts.capabilities {}))]
              (each [server server-opts (pairs opts.servers)]
                (let [final-server-opts
                       (vim.tbl_deep_extend "force"
                         {:capabilities (vim.deepcopy capabilities)}
                         (or server_opts {}))]
                  (if (. opts :setup server)
                    ((. opts :setup server) server final-server-opts)
                    ((. (require "lspconfig") server :setup) final-server-opts))))))}]
