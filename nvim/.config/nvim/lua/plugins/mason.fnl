; plugins/mason.fnl
; TODO: Update packages regularly? Reminder?
(local {: autoload} (require :nfnl.module))
(local {: update : merge} (autoload :nfnl.core))

[{1 :williamboman/mason.nvim
  :dependencies [:williamboman/mason-lspconfig.nvim]
  :opts (fn [_ opts]
          (-> opts
              (update :ensure-installed #(or $ []))
              (update :mason-lspconfig #(or $ {}))
              (update :mason-lspconfig #(merge $ {:automatic_installation true}))))
  :config (fn [_ opts]
            (let [mason (require "mason")
                  mason-lspconfig (require "mason-lspconfig")
                  mr (require "mason-registry")]
              (mason.setup opts)
              (mason-lspconfig.setup opts.mason-lspconfig)
              (mr.refresh
                #(each [_ tool (ipairs opts.ensure-installed)]
                   (let [p (mr.get_package tool)]
                     (if (not (p:is_installed))
                       (p:install)))))))}]
