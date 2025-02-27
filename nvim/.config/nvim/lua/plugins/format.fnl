; plugins/format.fnl
(local {: autoload} (require :nfnl.module))
(local {: get : assoc} (autoload :nfnl.core))
(local conform (autoload :conform))

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
            (let [format_on_save (get opts :format_on_save {})]
              (-> opts
                  (assoc :format_on_save #(let [ft (vim.api.nvim_buf_get_option $ "filetype")]
                                            (when (not (get opts.no_format_on_save ft))
                                              (_G.P "format_on_save")
                                              format_on_save)))
                  (conform.setup))))}]
