local M = {}
local fn = vim.fn

local function get_color(group, attr)
    return fn.synIDattr(fn.synIDtrans(fn.hlID(group)), attr)
end

local hl_fg = get_color('LineNr', 'fg#')

local config = {
    amount = 2,
    distance = 5,

    hl_properties = {
        underline = true,
        fg = hl_fg,
        sp = hl_fg,
    },

    enable_autocmd = true,
    autocmd_pattern = "*",
}

M.setup = function(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
    vim.g.relpointers_config = config -- Replace with better way to toggle plugin
    vim.g.relpointers_enabled = true  -- Possibly allow buffer-local toggling in future?

    if (config.enable_autocmd) then
        -- autogroup
        local group = vim.api.nvim_create_augroup("Relative", { clear = true })
        -- autocmd
        autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = group,
            pattern = config.autocmd_pattern,
            callback = M.start,
        })
    end
end

local function render_pointers_match(buf_nr, namespace, line_nr)
    local current_line_nr, _ = unpack(vim.api.nvim_win_get_cursor(0))

    local line_content = vim.api.nvim_buf_get_lines(buf_nr, line_nr - 1, line_nr, false)
    local pointer_text = line_content[1]
    local indent = fn.indent(line_nr)
    local offset_str = tostring(math.abs(current_line_nr - line_nr))

    if indent < 2 * vim.bo.shiftwidth then
        vim.fn.matchaddpos("RelPointersHl", { {
            line_nr,
            2 * vim.bo.shiftwidth - string.len(offset_str),
            string.len(offset_str),
        } })
    end
    if (pointer_text == "") then
        vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, 0, {
            virt_text = { { offset_str, "RelPointersHL" } },
            virt_text_win_col = 2 * vim.bo.shiftwidth - 1 - string.len(offset_str),
            strict = false,
        })
    elseif indent >= 2 * vim.bo.shiftwidth then
        vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, 0, {
            virt_text = { { offset_str, "RelPointersHL" } },
            virt_text_win_col = 2 * vim.bo.shiftwidth - 1 - string.len(offset_str),
            strict = false,
        })
    end
end

local function define_positions(line_nr, buf_nr, namespace, direction)
    local amount = config.amount
    local distance = config.distance

    local offset = line_nr + (direction * (amount * distance))

    for i = line_nr + (direction * distance), offset, (direction * distance) do
        if (i > 0) then
            render_pointers_match(buf_nr, namespace, i)
        end
    end
end

M.start = function()
    -- highlight group
    vim.api.nvim_set_hl(0, "RelPointersHl", config.hl_properties)

    local buf_nr = vim.api.nvim_get_current_buf()
    local line_nr = fn.line(".")
    local namespace = vim.api.nvim_create_namespace("relpointers")

    -- clearing
    fn.clearmatches()
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

    -- below cursor
    define_positions(line_nr, buf_nr, namespace, 1)
    -- above cursor
    define_positions(line_nr, buf_nr, namespace, -1)
end

-- disable plugin
M.disable = function()
    vim.api.nvim_del_autocmd(autocmd_id)
    local namespaces = vim.api.nvim_get_namespaces()
    local namespace = namespaces["relpointers"]
    vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
    fn.clearmatches()
end

-- toggle plugin
M.toggle = function()
    if vim.g.relpointers_enabled then
        M.disable()
        vim.g.relpointers_enabled = false
    else
        M.setup(vim.g.relpointers_config)
        vim.g.relpointers_enabled = true
    end
end

return M
