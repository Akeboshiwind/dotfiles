; plugins/lang/yaml.fnl

[{1 :williamboman/mason.nvim
  :opts (fn [_ opts]
          (set opts.ensure_installed (or opts.ensure_installed []))
          (vim.list_extend opts.ensure_installed
            [:cfn-lint :actionlint :yamllint])
          opts)}
 {1 :mfussenegger/nvim-lint
  :opts {:linters_by_ft {:yaml [:cfn_lint :actionlint :yamllint]}
         :linters {:cfn_lint
                   {:ignore_exitcode true
                    :condition (fn [{: dirname}]
                                 (or (string.match dirname "cloudformation")
                                     (string.match dirname "cfn")))}
                   :actionlint
                   {:condition (fn [{: dirname}]
                                 (print dirname)
                                 (string.match dirname ".github/workflows"))}}}}

 {1 :neovim/nvim-lspconfig
  :opts {:servers
         {:yamlls
          {:settings
           {:yaml
            {:format {:enable true}
             :validate {:enable true}
             :schemaStore {:enable true}
             :customTags ["!And scalar"
                          "!And mapping"
                          "!And sequence"                
                          "!If scalar"
                          "!If mapping"
                          "!If sequence"                
                          "!Not scalar"
                          "!Not mapping"
                          "!Not sequence"                
                          "!Equals scalar"
                          "!Equals mapping"
                          "!Equals sequence"                
                          "!Or scalar"
                          "!Or mapping"
                          "!Or sequence"                
                          "!FindInMap scalar"
                          "!FindInMap mappping"        
                          "!FindInMap sequence"
                          "!Base64 scalar"
                          "!Base64 mapping"
                          "!Base64 sequence"                
                          "!Cidr scalar"
                          "!Cidr mapping"
                          "!Cidr sequence"                
                          "!Ref scalar"
                          "!Ref mapping"
                          "!Ref sequence"                
                          "!Sub scalar"
                          "!Sub mapping"
                          "!Sub sequence"                
                          "!GetAtt scalar"
                          "!GetAtt mapping"
                          "!GetAtt sequence"                
                          "!GetAZs scalar"
                          "!GetAZs mapping"
                          "!GetAZs sequence"                
                          "!ImportValue scalar"
                          "!ImportValue mapping"
                          "!ImportValue sequence"                
                          "!Select scalar"
                          "!Select mapping"
                          "!Select sequence"
                          "!Split scalar"
                          "!Split mapping"
                          "!Split sequence"                
                          "!Join scalar"
                          "!Join mapping"
                          "!Join sequence"]}}}}}}]                
