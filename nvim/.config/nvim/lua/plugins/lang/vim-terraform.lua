-- plugins/lang/vim-terraform.lua

local M = {
    "hashivim/vim-terraform",
    enabled = false,
}

function M.config()
    vim.g.terraform_fmt_on_save = 1
end

return M
