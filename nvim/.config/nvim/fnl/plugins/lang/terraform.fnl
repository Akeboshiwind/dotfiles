; plugins/lang/terraform.fnl

[; TODO: Install terraform via mason?
 ; TODO: terraform-ls?
 {1 :stevearc/conform.nvim
  :opts {:formatters_by_ft {:terraform ["terraform_fmt"]}}}]
