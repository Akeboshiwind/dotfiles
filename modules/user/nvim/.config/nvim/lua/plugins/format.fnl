; plugins/format.fnl
(local {: autoload} (require :nfnl.module))
(local {: get : assoc} (autoload :nfnl.core))
(local conform (autoload :conform))
(local cfg (autoload :util.cfg))

(local create-command vim.api.nvim_create_user_command)
(var enabled true)

(create-command "ConformOff"
                #(do
                   (set enabled false)
                   (print "Conform formatting disabled"))
                {:desc "Disable Conform Formatting"})
(create-command "ConformOn"
                #(do 
                   (set enabled true)
                   (print "Conform formatting enabled"))
                {:desc "Enable Conform Formatting"})

[{1 :stevearc/conform.nvim
  :event [:BufWritePre]
  :cmd [:ConformInfo]
  :keys [{1 "<leader>F" 2 #(conform.format) :desc "Format buffer"}]
  :format/by-ft {}
  :format/formatters {}
  :format/no-on-save {}
  :opts {:format_on_save {:lsp_fallback true
                          :timeout_ms 500}}
  :config (fn [_ opts G]
            (let [format-on-save (or opts.format_on_save {})
                  no-format-on-save (cfg.merge-all G.format/no-on-save)
                  format-on-save-fn
                  #(let [ft (vim.api.nvim_buf_get_option $ "filetype")]
                     (when (and enabled (not (get no-format-on-save ft)))
                       format-on-save))]
              (conform.setup
                (-> opts
                    (assoc :format_on_save format-on-save-fn)
                    (assoc :formatters_by_ft (cfg.merge-all G.format/by-ft))
                    (assoc :formatters (cfg.merge-all G.format/formatters))))))}]
