local M = {}

local config = {
    amount = 2,
    distance = 5,

    hl_properties = { underline = true },

    pointer_style = "line region",

    virtual_pointer_position = -4,
    virtual_pointer_text = "@",

    enable_autocmd = true,
    autocmd_pattern = "*",

    white_space_rendering = "\t\t\t\t\t",
}

M.setup = function(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})

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
    vim.fn.matchaddpos("RelPointersHl", { line_nr })

    local line_content = vim.api.nvim_buf_get_lines(buf_nr, line_nr - 1, line_nr, false)
    local pointer_text = line_content[1]

    if (pointer_text == "") then
        vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, 0,
            { virt_text_pos = "overlay", virt_text = { { tostring(math.abs(current_line_nr - line_nr)), "RelPointersHL" } },
                virt_text_win_col = 0 })
    end
end

local function render_pointers_virt(buf_nr, namespace, line_nr)
    local virtual_text = { {
        config.virtual_pointer_text,
        -- "IncSearch",
        "RelPointersHL",
    } }
    if line_nr <= vim.fn.line("$") then
        vim.api.nvim_buf_set_extmark(buf_nr, namespace, line_nr - 1, 0,
            { virt_text_pos = "overlay", virt_text = virtual_text, virt_text_win_col = config.virtual_pointer_position})
    end
end

local function define_positions(line_nr, buf_nr, namespace, direction)
    local amount = config.amount
    local distance = config.distance

    local offset = line_nr + (direction * (amount * distance))

    for i = line_nr + (direction * distance), offset, (direction * distance)  do
        if (i > 0) then
            if (config.pointer_style == "line region") then
                render_pointers_match(buf_nr, namespace, i)
            elseif (config.pointer_style == "virtual") then
                render_pointers_virt(buf_nr, namespace, i)
            end
        end
    end
end

M.start = function()
    local amount = config.amount
    local distance = config.distance
    -- highlight group
    vim.api.nvim_set_hl(0, "RelPointersHl", config.hl_properties)

    local buf_nr = vim.api.nvim_get_current_buf()
    local line_nr = vim.fn.line(".")
    local namespace = vim.api.nvim_create_namespace("relpointers")

    -- clearing
    vim.fn.clearmatches()
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
    vim.fn.clearmatches()
end

return M
