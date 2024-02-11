-- plugins/lang/terraform.lua

return {
    -- TODO: Install terraform via mason?
    -- TODO: terraform-ls?
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                terraform = { "terraform_fmt" },
            },
        },
    },
}
