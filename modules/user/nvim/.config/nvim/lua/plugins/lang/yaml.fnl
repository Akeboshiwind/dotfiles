; plugins/lang/yaml.fnl

[{1 :williamboman/mason.nvim
  :opts {:ensure-installed {:cfn-lint true
                            :actionlint true
                            :yamllint true}}}
 {1 :mfussenegger/nvim-lint
  :opts {:linters_by_ft {:yaml [:cfn_lint :actionlint :yamllint]}
         :linters {:cfn_lint
                   {:ignore_exitcode true
                    :condition (fn [{: dirname}]
                                 (or (string.match dirname "cloudformation")
                                     (string.match dirname "cfn")))}
                   :actionlint
                   {:condition (fn [{: dirname}]
                                 (string.match dirname ".github/workflows"))}}}}
 {1 :kevinhwang91/nvim-ufo
  :opts
  {:fold-queries
   {:yaml
    "; services in docker-compose.yml
     (block_mapping_pair
       key: (_ (_ (string_scalar) @service_key))
       value: (_ (_ (block_mapping_pair) @fold.custom))
       (#eq? @service_key \"services\"))"}}}

 ;; I don't think this was really doing anything tbh
 ;; Really, the above linters work just fine for me
 (comment
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
                            "!Join sequence"]}}}}}})]                

