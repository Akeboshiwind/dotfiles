;; util.fnl

(fn on_very_lazy [f]
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

; Would something like this be useful?
; For this:
; ((. (require "something") :method) a b c)
; (call (require "something") :method a b c)
(comment
  (fn call [obj method ...]
    ((. obj method) (unpack ...))))

(local lsp {})

(fn lsp.on_attach [on-attach]
  (vim.api.nvim_create_autocmd "LspAttach"
    {:callback (fn [args]
                 (let [buffer args.buf
                       client (vim.lsp.get_client_by_id
                                args.data.client_id)]
                   (on-attach client buffer)))}))

{: on_very_lazy
 : debounce
 : lsp}
