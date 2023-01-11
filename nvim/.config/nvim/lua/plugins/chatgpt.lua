-- chatgpt.lua

local M = {
    "jackMort/ChatGPT.nvim",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
}

function M.file_exists(path)
    local f = io.open(path, "rb")
    if f then
        f:close()
    end
    return f ~= nil
end

-- Assumes there is a file ~/.config/openai/api_key
-- That contains a single line with the api key on it
function M.load_api_key()
    local api_key_path = vim.fn.expand("$HOME") .. "/.config/openai/api_key"

    if not M.file_exists(api_key_path) then
        vim.notify("ChatGPT: API key not found at " .. api_key_path, vim.log.levels.WARN)
        return nil
    end

    local api_key = io.open(api_key_path):read("*l")

    return api_key
end

function M.config()
    local api_key = M.load_api_key()
    if api_key == nil then
        return
    end

    vim.env.OPENAI_API_KEY = api_key

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
            e = {
                function()
                    chatgpt.edit_with_instructions()
                end,
                "Edit with instructions",
            },
        },
    }, { prefix = "<leader>" })

    wk.register({
        p = {
            name = "ChatGPT",
            e = {
                function()
                    chatgpt.edit_with_instructions()
                end,
                "Edit with instructions",
            },
        },
    }, {
        prefix = "<leader>",
        mode = "v",
    })
end

return M
