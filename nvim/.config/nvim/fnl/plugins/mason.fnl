; plugins/mason.fnl
; TODO: Update packages regularly? Reminder?

[{1 :williamboman/mason.nvim
  :dependencies [:williamboman/mason-lspconfig.nvim]
  :opts (fn [_ opts]
          (set opts.ensure_installed (or opts.ensure_installed []))
          (set opts.mason_lspconfig
               (or opts.mason_lspconfig
                   {:automatic_installation true}))
          opts)
  :config (fn [_ opts]
            ((. (require "mason") :setup) opts)
            ((. (require "mason-lspconfig") :setup) opts.mason_lspconfig)
            (let [mr (require "mason-registry")]
              (mr.refresh
                #(each [_ tool (ipairs opts.ensure_installed)]
                   (let [p (mr.get_package tool)]
                     (if (not (p:is_installed))
                       (p:install)))))))}]
