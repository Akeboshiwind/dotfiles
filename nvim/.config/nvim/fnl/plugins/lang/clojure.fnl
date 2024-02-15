; plugins/lang/clojure.fnl
; TODO: Move conjure stuff to it's own file

[{1 :neovim/nvim-lspconfig
  :opts {:servers
         {:clojure_lsp
          {:init_options
           {"cljfmt-config-path"
            (.. (vim.fn.stdpath "config")
                "/config/.cljfmt.edn")}}}}}
 {1 :PaterJason/cmp-conjure
  :dependencies [:hrsh7th/nvim-cmp]}
 {1 :eraserhd/parinfer-rust
  :build "cargo build --release"}
 {1 :folke/which-key.nvim
  :opts {:defaults
         ; TODO: These don't work, why?
         {"<leader>l" {:name "log"}
          "<leader>e" {:name "eval"}
          "<leader>c" {:name "display as comment"}
          "<leader>g" {:name "goto"}

          ; Clojure nrepl specific
          "<leader>G" {:name "git"}
          "<leader>v" {:name "view"}
          "<leader>s" {:name "session"}
          "<leader>t" {:name "test"}
          "<leader>r" {:name "refresh"}}}}

 {1 :Olical/conjure
  :tag "v4.50.0"
  :dependencies [:nvim-telescope/telescope.nvim
                 ;:gpanders/nvim-parinfer
                 :eraserhd/parinfer-rust
                 :PaterJason/cmp-conjure]
  :opts {:config
         {"mapping#prefix" "<leader>"

          ; Briefly highlight evaluated forms
          "highlight#enabled" true

          ; TODO: Remove and enable for all?
          "filetypes" ["clojure" "fennel"]

          ; Disable the mapping for selecting a session as that collides with searching)
          ; files within a project
          "client#clojure#nrepl#mapping#session_select" false
          ; Disable auto-starting a babashka repl
          "client#clojure#nrepl#connection#auto_repl#enabled" false}}
  :config (fn [_ opts]
            ; >> Configure
            (each [k v (pairs opts.config)]
              (tset vim.g (string.format "conjure#%s" k) v))

            ; >> Mappings
            (let [pickers (require "telescope.pickers")]
                finders (require "telescope.finders")
                conf (. (require "telescope.config") :values)
                actions (require "telescope.actions")
                action-state (require "telescope.actions.state"))

            (fn shadow-select [opts]
              (let [opts (or opts {})
                    ; A set used to de-duplicate the entries
                    ; To use a table as a set, use the keys as values
                    ; # Insertion:
                    ; (tset set value true)
                    ; # Contains?
                    ; (if (. set value)
                    ;   (print "contains"))
                    ; See: https://www.lua.org/pil/11.5.html
                    entry_cache {}]

                  ; Does three things to the `ps aux` output:
                  ;  - Filters for shadow-cljs watch commands
                  ;  - Returns the app name
                  ;  - De-duplicates the results
                  (set opts.entry_maker
                    (fn [entry]
                      ; NOTE: Have to put the `-` in a set for some reason...
                      ; TODO: when-let?
                      (let [app (entry:match "shadow[-]cljs watch (%w*)")]
                        (when app
                          ; Cache the entry
                          (when (not (. entry_cache app))
                            (tset entry_cache app true)
                            {:value app
                             :display app
                             :ordinal app})))))

                  (-> pickers
                      (#((. $1 :new)
                         opts
                         {:prompt_title "shadow-cljs apps"
                          :finder (finders.new_oneshot_job ["ps" "aux"] opts)
                          :sorter (conf.generic_sorter opts)
                          :attach_mappings 
                          (fn [prompt_bufnr _]
                            ; When an app is selected, run ConjureShadowSelect
                            (actions.select_default:replace
                              #(do
                                 (actions.close prompt_bufnr)
                                 (let [selection (action_state.get_selected_entry)
                                       app selection.value]

                                   (vim.cmd (string.format "ConjureShadowSelect %s" app)))
                                 true)))}))
                        
                      (: :find))))

            ; >> Document Mappings
            (let [wk (require "which-key")]

              ; Base Conjure Mappings
              (wk.register
                {:e {:g [":ConjureEval (user/go!)<CR>" "user/go!"]
                     :s [#(do
                            ; Save buffer
                            (vim.cmd "w")

                            ; clerk/show!
                            (let [filename (vim.fn.expand "%:p")]
                              (vim.cmd (string.format "ConjureEval (nextjournal.clerk/show! \"%s\")" filename))))
                         "clerk/show!"]}
                 :s {:S [shadow_select "Conjure Select Shadowcljs Environment"]}}
                {:prefix "<leader>"})))}]
