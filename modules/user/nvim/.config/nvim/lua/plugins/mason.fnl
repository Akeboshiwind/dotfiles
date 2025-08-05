; plugins/mason.fnl
; TODO: Update packages regularly? Reminder?
(local {: autoload} (require :nfnl.module))
(local fun (autoload :vend.luafun))
(local mason (autoload :mason))
(local mason-lspconfig (autoload :mason-lspconfig))
(local mr (autoload :mason-registry))
(local cfg (autoload :util.cfg))

[{1 :mason-org/mason.nvim
  :dependencies [:mason-org/mason-lspconfig.nvim]
  ; >> mason/ensure-installed
  ; Ensure these tools are installed
  :mason/ensure-installed []
  :opts {:mason-lspconfig {}}
  :config (fn [_ opts G]
            (mason.setup opts)
            (mason-lspconfig.setup opts.mason-lspconfig)
            (mr.refresh
              #(->> (fun.iter (cfg.flatten-1 G.mason/ensure-installed))
                    (fun.filter (fn [_tool install?] install?))
                    (fun.map (fn [tool _install?] (mr.get_package tool)))
                    (fun.filter #(not ($:is_installed)))
                    (fun.each #($:install)))))}]
