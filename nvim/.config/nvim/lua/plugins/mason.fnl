; plugins/mason.fnl
; TODO: Update packages regularly? Reminder?
(local {: autoload} (require :nfnl.module))
(local {: update : merge} (autoload :nfnl.core))
(local mason (autoload :mason))
(local mason-lspconfig (autoload :mason-lspconfig))
(local mr (autoload :mason-registry))

[{1 :williamboman/mason.nvim
  :dependencies [:williamboman/mason-lspconfig.nvim]
  :opts {; Ensure these tools are installed
         ; To add set it's value to anything truthy
         :ensure-installed {}
         :mason-lspconfig {:automatic_installation true}}
  :config (fn [_ opts]
            (mason.setup opts)
            (mason-lspconfig.setup opts.mason-lspconfig)
            (mr.refresh
              #(each [tool install? (pairs opts.ensure-installed)]
                 (print (vim.inspect tool))
                 (if install?
                   (let [p (mr.get_package tool)]
                     (if (not (p:is_installed))
                       (p:install)))))))}]
