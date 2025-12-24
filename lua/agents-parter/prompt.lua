local M = {}--[[ Opens a floating window to get user input--@param callback function(input: string)]]function M.open_prompt(callback)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.3)
  local height = 4

  -- Calculate position near cursor, but keep it on screen
  local screen_row = vim.fn.screenrow()
  local screen_col = vim.fn.screencol()

  local row = 1
  local col = 0

  -- If near the bottom, show above cursor
  if screen_row + height + 2 > vim.o.lines then
    row = -height - 1
  end

  -- If near the right edge, shift left
  if screen_col + width > vim.o.columns then
    col = vim.o.columns - screen_col - width
  end

  local opts = {
    relative = "cursor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "Ask (Ctrl+Enter to submit) ",
    title_pos = "center",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- Set buffer options
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  -- Map Ctrl+Enter to submit
  -- In some terminals <C-CR> might be <C-Enter> or other codes.
  -- Common terminal escape for C-Enter is often not standard, 
  -- but <C-j> or <C-m> might work, or literal <C-CR>.
  local function submit()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local input = table.concat(lines, "\n")
    vim.api.nvim_win_close(win, true)
    if input ~= "" then
      callback(input)
    end
  end

  vim.keymap.set('i', '<C-CR>', submit, { buffer = buf })
  vim.keymap.set('n', '<C-CR>', submit, { buffer = buf })
  -- Fallback for terminals that don't support <C-CR>
  vim.keymap.set('i', '<C-Enter>', submit, { buffer = buf })
  vim.keymap.set('n', '<C-Enter>', submit, { buffer = buf })
  
  -- Escape to close
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })

  vim.cmd("startinsert")
end

return M
