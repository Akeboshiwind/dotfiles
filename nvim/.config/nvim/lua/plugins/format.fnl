; plugins/format.fnl
(local {: autoload} (require :nfnl.module))
(local {: get : assoc} (autoload :nfnl.core))
(local conform (autoload :conform))

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
  :opts {:formatters_by_ft {}
         :formatters {}
         :no_format_on_save {}
         :format_on_save {:lsp_fallback true
                          :timeout_ms 500}}
  :config (fn [_ opts]
            (let [format-on-save (get opts :format_on_save {})]
              (-> opts
                  (assoc :format_on_save #(let [ft (vim.api.nvim_buf_get_option $ "filetype")]
                                            (when (and enabled (not (get opts.no_format_on_save ft)))
                                              format-on-save)))
                  (conform.setup))))}]
