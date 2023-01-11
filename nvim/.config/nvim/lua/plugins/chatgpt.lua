-- chatgpt.lua

local M = {
    "jackMort/ChatGPT.nvim",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
}

function file_exists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end

function M.config()
    local api_key_path = vim.fn.expand("$HOME") .. "/.config/openai/api_key"
    if not file_exists(api_key_path) then
        vim.notify("ChatGPT: API key not found at " .. api_key_path, vim.log.levels.WARN)
        return
    end

    vim.env.OPENAI_API_KEY = io.open(api_key_path):read("*a")

    local chatgpt = require("chatgpt")
    chatgpt.setup({})

    local wk = require("which-key")

    wk.register({
        p = {
            name = "ChatGPT",
            c = {
                function()
                    chatgpt.openChat()
                end,
                "Chat with ChatGPT",
            },
            a = {
                function()
                    chatgpt.selectAwesomePrompt()
                end,
                "ActAs",
            },
        },
    }, { prefix = "<leader>" })
end

return M
