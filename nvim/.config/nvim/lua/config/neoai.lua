-- config/neoai.lua

local M = {}

--- Sets the context of the current buffer by getting the range of selected lines
-- and passing it to the `set_context` function from the `neoai.chat` module.
--
function M.set_context()
    local buffer = vim.api.nvim_get_current_buf()

    line1 = vim.fn.line("'<")
    line2 = vim.fn.line("'>")

    require("neoai.chat").set_context(buffer, line1, line2)
end

--- Opens the NeoAI chat window with the given prompt text.
-- Any existing text in the prompt window is cleared before the new prompt is added.
-- @param prompt The prompt to add to the prompt window.
function M.fill_prompt(prompt)
    -- Open the sidebar if not already
    require("neoai").toggle(true)

    -- Force the focus to the prompt buffer
    vim.api.nvim_set_current_win(require("neoai.ui").input_popup.winid)

    -- Clear the prompt buffer
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {})

    -- Put the prompt into the buffer
    vim.api.nvim_put(prompt, "c", true, true)
end

--- Returns a table with just the keys from the given table.
-- @param tbl The table to get the keys from.
function keys(tbl)
    local result = {}
    for k, _ in pairs(tbl) do
        result[#result + 1] = k
    end
    return result
end

--- Processes the given prompts table into a table of functions that return the prompt
function process_prompts(prompts)
    local result = {}
    for k, v in pairs(prompts) do
        local prompt_fn
        if type(v) == "function" then
            prompt_fn = v
        else
            local prompt
            if type(v) == "table" then
                prompt = v
            else
                prompt = { v }
            end

            prompt_fn = function()
                return prompt
            end
        end

        result[k] = prompt_fn
    end
    return result
end

--- Opens a telescope prompt picker with the given prompts.
--
-- @param opts.prompts The prompts to display in the picker.
-- @param opts.prompt_title The title of the prompt picker.
-- @param opts.select_action A function that's called when enter is pressed on an entry
function M.prompt_select(opts)
    -- Config
    local opts = opts or {}

    assert(opts.prompts, "opts.prompts is required")
    local prompts = process_prompts(opts.prompts)
    opts.prompt_title = opts.prompt_title or "prompts"
    opts.select_action = opts.select_action or M.fill_prompt

    -- Dependencies
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local previewers = require("telescope.previewers")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers
        .new(opts, {
            prompt_title = opts.prompt_title,
            finder = finders.new_table(keys(prompts)),
            sorter = conf.generic_sorter(opts),
            previewer = previewers.new_buffer_previewer({
                define_preview = function(self, entry, status)
                    return require("telescope.previewers.utils").with_preview_window(status, nil, function()
                        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, prompts[entry.value](entry.value))
                    end)
                end,
            }),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    local prompt = prompts[selection.value](selection.value)

                    opts.select_action(prompt)
                end)
                return true
            end,
        })
        :find()
end

return M
