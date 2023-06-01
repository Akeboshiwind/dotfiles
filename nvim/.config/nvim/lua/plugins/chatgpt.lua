-- chatgpt.lua

local M = {
    "Bryley/neoai.nvim",
    dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-telescope/telescope.nvim",
    },
    -- TODO: Lazy
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

M.prompts = {
    ["nvim-lua"] = { "In nvim, using lua:", "" },
}

M.visual_prompts = {
    ["summarise"] = { "Summarise the given text in 1-2 lines.", "" },
    ["doc string"] = {
        "Output a docstring in a codeblock for the given code.",
        "Do not output the code as well, just the docstring",
        "",
    },
    ["clarity suggestions"] = {
        "Output a bullet point list of suggestions to improve clarity.",
        "Format this as up to 5 'specific' suggestions, these suggestions should point to specific parts of the text.",
        "Follow these with up to 3 'generic' suggestions which can suggest general things the text could improve on.",
        "If you don't have enough suggestions you think are relevant, then include include less rather trying to fill out as many as possible.",
        "",
    },
}

function M.visual_prompt_select()
    local neoai_utils = require("config.neoai")
    neoai_utils.prompt_select({
        prompts = M.visual_prompts,
        select_action = function(prompt)
            neoai_utils.set_context()
            neoai_utils.fill_prompt(prompt)
        end,
    })
end

function M.chat_with_context()
    require("config.neoai").set_context()
    -- Open the sidebar if not already
    require("neoai").toggle(true)
end

function M.config()
    -- >> Setup

    local open_api_key_env = "OPENAI_API_KEY"
    vim.env[open_api_key_env] = M.load_api_key()

    require("neoai").setup({
        open_api_key_env = open_api_key_env,
        shortcuts = {},
        ui = {
            submit = "<S-Enter>",
        },
    })

    -- >> Bindings

    local wk = require("which-key")

    -- Normal mode
    wk.register({
        ac = { ":NeoAI<CR>", "NeoAI Chat" },
        ap = {
            function()
                require("config.neoai").prompt_select({
                    prompts = M.prompts,
                })
            end,
            "Select prompt",
        },
    }, { prefix = "<leader>" })

    -- Visual mode
    wk.register({
        ap = {
            ":'<,'>lua require('plugins.chatgpt').visual_prompt_select()<CR>",
            "Select prompt",
        },
        ac = {
            ":'<,'>lua require('plugins.chatgpt').chat_with_context()<CR>",
            "Chat with context",
        },
    }, { mode = "v", prefix = "<leader>" })
end

return M
