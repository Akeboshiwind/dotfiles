; plugins/cmp.fnl
(local {: autoload} (require :nfnl.module))
(local cmp (autoload :cmp))
(local wk (autoload :which-key))

[{1 :hrsh7th/nvim-cmp
  :dependencies [:hrsh7th/cmp-nvim-lsp
                 :hrsh7th/cmp-buffer
                 :hrsh7th/cmp-path
                 :hrsh7th/cmp-cmdline
                 :lukas-reineke/cmp-rg]
  :init #(set vim.opt.completeopt ["menu" "menuone" "noselect"])

  ; NOTE: Intentionally left as a config function instead of opts
  ; This is for a few reasons:
  ; - Ordering really matters in some parts (sources),
  ;   - I'd rather keep things explicit
  ; - The config isn't just data, it relies on function calls
  ;   - I'd rather not remove them and rely on (potentially) internal details
  :config (fn []
            ; >> Setup
            (cmp.setup
              {:mapping {"<C-Space>" (cmp.mapping (cmp.mapping.complete) [:i :c])
                         "<CR>" (cmp.mapping.confirm
                                  {:select true
                                   :behavior cmp.ConfirmBehavior.Replace})
                         "<C-e>" (cmp.mapping
                                   {:i (cmp.mapping.abort)
                                    :c (cmp.mapping.close)})
                         "<C-u>" (cmp.mapping (cmp.mapping.scroll_docs -4) [:i :c])
                         "<C-d>" (cmp.mapping (cmp.mapping.scroll_docs 4) [:i :c])

                         "<Tab>" (cmp.mapping
                                   (fn [fallback]
                                     (if (cmp.visible)
                                         (cmp.select_next_item)
                                         (fallback)))
                                   [:i :c])
                         "<S-Tab>" (cmp.mapping
                                     (fn [fallback]
                                       (if (cmp.visible)
                                           (cmp.select_prev_item)
                                           (fallback)))
                                     [:i :c])}
               :sources (cmp.config.sources
                          [{:name :copilot}
                           {:name :path}
                            ;:option {:trailing_slash true}}

                           {:name :conjure}
                           {:name :nvim_lsp}

                           {:name :rg
                            :keyword_length 4}
                           {:name :buffer}])})

            ; Use buffer source for `/`
            (cmp.setup.cmdline ["/" "?"]
              {:mapping (cmp.mapping.preset.cmdline)
               :sources [{:name :buffer}]})

            ; Use cmdline * path source for `:`
            (cmp.setup.cmdline ":"
              {:mapping (cmp.mapping.preset.cmdline)
               :sources (cmp.config.sources
                          [{:name :path}
                           {:name :cmdline}])})

            ; >> Mappings
            (wk.add
              {:mode :i
               1 [{1 "<C-Space>" :desc "Invoke completion"}
                  {1 "<CR>"      :desc "Confirm selection or fallback"}
                  {1 "<C-e>"     :desc "Close the completion menu"}
                  {1 "<C-u>"     :desc "Page up"}
                  {1 "<C-d>"     :desc "Page down"}
                  {1 "<TAB>"     :desc "Next completion item"}
                  {1 "<S-TAB>"   :desc "Prev completion item"}]}))}]
