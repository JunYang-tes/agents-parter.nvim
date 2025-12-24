---@class gemini-nvim.Server
---@field status "STOPPED" | "RUNNING" | "CRASHED"
---@field job_id number the job id of the server
---@field port number the port of the server
local M = {
  status = "STOPPED",
  job_id = -1,
  port = -1,
}

local STATUS = {
  STOPPED = "STOPPED",
  RUNNING = "RUNNING",
  CRASHED = "CRASHED",
}

--- Starts the neovim-ide-companion
--- It sets the NVIM_LISTEN_ADDRESS environment variable,
--- finds an available port using `neovim-ide-port`,
--- and starts the `neovim-ide-companion` as a background job.
---@param force_new_port boolean? whether to force a new port
function M.start(force_new_port)
  if M.status == STATUS.RUNNING then
    return
  end

  local old_port = M.port
  local target_port = -1

  if old_port ~= -1 and not force_new_port then
    target_port = old_port
  else
    local port_output = vim.fn.system('neovim-ide-port')
    target_port = tonumber(port_output:match("%d+"))
  end

  if not target_port then
    vim.notify("neovim-ide-port not found", vim.log.levels.ERROR)
    M.status = STATUS.CRASHED
    return
  end

  local command = {
    'neovim-ide-companion',
    '--port=' .. target_port,
  }

  M.job_id = vim.fn.jobstart(command, {
    env = {
      NVIM_LISTEN_ADDRESS = vim.v.servername,
    },
    on_exit = function(_, exit_code)
      vim.notify("neovim-ide-companion server exited with code " .. exit_code)
      -- Check if this is still the active job we are tracking
      if M.port == target_port then
        if exit_code ~= 0 then
          if target_port == old_port and old_port ~= -1 then
            -- Failed with old port, try a new one
            M.status = STATUS.STOPPED
            M.job_id = -1
            M.start(true)
            return
          end
          M.status = STATUS.CRASHED
        else
          M.status = STATUS.STOPPED
        end
        M.job_id = -1
      end
    end
  })

  if M.job_id > 0 then
    M.status = STATUS.RUNNING
    M.port = target_port
    if old_port ~= -1 and target_port ~= old_port then
      vim.notify("neovim-ide-companion server started on NEW port " .. target_port .. ". Please restart your agent program.",
        vim.log.levels.WARN)
    else
      vim.notify("neovim-ide-companion server started on port " .. target_port)
    end
  else
    M.status = STATUS.CRASHED
    vim.notify("neovim-ide-companion server failed to start", vim.log.levels.ERROR)
  end
end

--- Stops the neovim-ide-companion
function M.stop()
  if M.job_id > 0 then
    M.status = STATUS.STOPPED
    vim.fn.jobstop(M.job_id)
    M.job_id = -1
  end
end

--- Shows a floating window with the server status
function M.show_status()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 40
  local height = 10
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
    title = " Gemini Server Status ",
    title_pos = "center",
  }
  local win = vim.api.nvim_open_win(buf, true, opts)

  local function update_buf()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local status_text = "Status: " .. M.status
    local port_text = "Port: " .. (M.port > 0 and tostring(M.port) or "N/A")
    local lines = {
      "",
      "  " .. status_text,
      "  " .. port_text,
      "",
      "  [s] Start Server",
      "  [k] Stop Server",
      "  [q] Close Window",
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Highlight status
    local hl_group = "Comment"
    if M.status == STATUS.RUNNING then
      hl_group = "String"
    elseif M.status == STATUS.CRASHED then
      hl_group = "ErrorMsg"
    end
    vim.api.nvim_buf_add_highlight(buf, -1, hl_group, 1, 10, -1)
  end

  update_buf()

  vim.keymap.set('n', 's', function()
    M.start()
    update_buf()
  end, { buffer = buf, silent = true })
  vim.keymap.set('n', 'k', function()
    M.stop()
    update_buf()
  end, { buffer = buf, silent = true })
  vim.keymap.set('n', 'x', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, silent = true })
  vim.keymap.set('n', '<Esc>', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, silent = true })
  vim.keymap.set('n', 'q', function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, silent = true })
end

return M
