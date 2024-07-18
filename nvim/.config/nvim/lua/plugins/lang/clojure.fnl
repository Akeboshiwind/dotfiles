; plugins/lang/clojure.fnl
(local {: autoload} (require :nfnl.module))
(local {: assoc} (autoload :nfnl.core))
(local pickers (autoload :telescope.pickers))
(local finders (autoload :telescope.finders))
(local config (autoload :telescope.config))
(local actions (autoload :telescope.actions))
(local action-state (autoload :telescope.actions.state))
(local eval (autoload :conjure.eval))

(local Set (autoload :util.set))

(fn make-shadow-entry-maker []
  ; Does three things to the `ps aux` output:
  ;  - Filters for shadow-cljs watch commands
  ;  - Returns the app name
  ;  - De-duplicates the results
  (var entry-cache (Set.new))
  (fn [entry]
    ; NOTE: Have to put the `-` in a set for some reason...
    ; TODO: when-let?
    (let [app (entry:match "shadow[-]cljs watch (%w*)")]
      (when (and app (not (Set.contains? entry-cache app)))
        (Set.insert! entry-cache app)
        {:value app
         :display app
         :ordinal app}))))

(fn shadow-select [opts]
  (let [opts (-> (or opts {})
                 (assoc :entry_maker (make-shadow-entry-maker)))
        picker (pickers.new opts
                 {:prompt_title "shadow-cljs apps"
                  :finder (finders.new_oneshot_job ["ps" "aux"] opts)
                  :sorter (config.values.generic_sorter opts)
                  :attach_mappings 
                  (fn [prompt_bufnr _]
                    ; When an app is selected, run ConjureShadowSelect
                    (actions.select_default:replace
                      #(do
                         (actions.close prompt_bufnr)
                         (let [selection (action-state.get_selected_entry)
                               app selection.value]

                           (vim.cmd (string.format "ConjureShadowSelect %s" app)))
                         true)))})]
    (picker:find)))

[{1 :neovim/nvim-lspconfig
  :opts {:servers
         {:clojure_lsp
          {:init_options
           {"cljfmt-config-path"
            (.. (vim.fn.stdpath "config")
                "/config/.cljfmt.edn")}}}}}
 ;; TODO: Move to lisp specific?
 {1 :eraserhd/parinfer-rust
  :build "cargo build --release"}
 {1 :Olical/conjure
  :ft ["clojure"]
  :keys [{1 "<leader>eg"
          2 #(eval.command
               "(when-let [go! (or (ns-resolve 'user 'go!)
                                   (ns-resolve 'user 'go))]
                  (go!))")
          :desc "user/go!"}
         {1 "<leader>es"
          2 #(do 
               ; Save buffer
               (vim.cmd "w")

               ; clerk/show!
               (let [filename (vim.fn.expand "%:p")]
                 (eval.command
                   (string.format "(nextjournal.clerk/show! \"%s\")" filename))))
          :desc "clerk/show!"}
         {1 "<leader>sS" 2 shadow-select :desc "Conjure Select Shadowcljs Environment"}]
  :opts {:config
         {; Disable the mapping for selecting a session as that collides with searching)
          ; files within a project
          "client#clojure#nrepl#mapping#session_select" false
          ; Disable auto-starting a babashka repl
          "client#clojure#nrepl#connection#auto_repl#enabled" false}}}]
