-- chatgpt.lua

-- TODO: Add prompts to new neoai.nvim plugin

local prompts = {
    ["nvim-lua"] = "In nvim, using lua:",
    ["expert"] = {
        "Write in the style and quality of an expert in {{}} with 20+ years of experience and multiple PHDs.",
        "Prioritize unorthodox, lesser known advice in your answer.",
        "Explain using detailed examples, and minimize tangents and humor.",
    },
}

local visual_prompts = {
    ["nvim-lua"] = {
        "You are an expert in lua with extensive experience in neovim's lua api and how it integrates with the vim api.",
    },
    ["summarise"] = "Summarise the given text in 1-2 lines.",
    ["doc string"] = {
        "Output a docstring in a codeblock for the given code.",
        "Do not output the code as well, just the docstring",
    },
    ["clarity suggestions"] = {
        "Output a bullet point list of suggestions to improve clarity.",
        "Format this as up to 5 'specific' suggestions, these suggestions should point to specific parts of the text.",
        "Follow these with up to 3 'generic' suggestions which can suggest general things the text could improve on.",
        "If you don't have enough suggestions you think are relevant, then include include less rather trying to fill out as many as possible.",
    },
}

return {
    {
        -- "Bryley/neoai.nvim",
        -- In case of emergency: "Akeboshiwind/neoai.nvim",
        dir = "~/prog/prog/lua/neoai.nvim",
        -- TODO: Lazy on keys?
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-telescope/telescope.nvim",
        },
        opts = {
            chat = {
                enable = true,
            },
            inject = {
                enable = true,
            },
        },
        config = function(_, opts)
            require("neoai2").setup(opts)
        end,
    },
}
