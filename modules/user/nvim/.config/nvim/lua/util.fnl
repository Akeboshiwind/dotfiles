;; util.fnl

(fn on-very-lazy [f]
  (vim.api.nvim_create_autocmd "User"
    {:pattern "VeryLazy"
     :callback (fn [] (f))}))

(fn debounce [ms f]
  (let [timer (vim.loop.new_timer)]
    (fn [...]
      (let [argv [...]]
        (timer:start ms 0
          (fn []
            (timer:stop)
            ((vim.schedule_wrap f) (unpack argv))))))))

(local lsp {})

(fn lsp.on-attach [on-attach]
  (vim.api.nvim_create_autocmd "LspAttach"
    {:callback (fn [args]
                 (let [buffer args.buf
                       client (vim.lsp.get_client_by_id
                                args.data.client_id)]
                   (on-attach client buffer)))}))

{: on-very-lazy
 : debounce
 : lsp}
