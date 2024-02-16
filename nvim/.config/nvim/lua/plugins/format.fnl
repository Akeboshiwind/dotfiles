; plugins/format.fnl

[{1 :stevearc/conform.nvim
  :event [:BufWritePre]
  :cmd [:ConformInfo]
  :opts {:formatters_by_ft {}
         :format_on_save {:timeout_ms 500
                          :lsp_fallback true}
          
         :formatters {}}}]
         
