---@class gemini-nvim.Server
---@field running boolean whether the server is running
---@field job_id number the job id of the server
---@field port number the port of the server
local M = {
  running = false,
  job_id = -1,
  port = -1,
}

--- Starts the neovim-ide-companion
--- It sets the NVIM_LISTEN_ADDRESS environment variable,
--- finds an available port using `neovim-ide-port`,
--- and starts the `neovim-ide-companion` as a background job.
function M.start()
  if M.running then
    return
  end

  local port = vim.fn.system('neovim-ide-port')
  port = tonumber(port:match("%d+"))
  if not port then
    vim.notify("neovim-ide-port not found", vim.log.levels.ERROR)
    return
  end

  local command = {
    'neovim-ide-companion',
    '--port=' .. port,
  }

  M.job_id = vim.fn.jobstart(command, {
    env = {
      NVIM_LISTEN_ADDRESS = vim.v.servername,
    },
    on_exit = function()
      M.running = false
      M.job_id = -1
      M.port = -1
    end
  })

  if M.job_id > 0 then
    M.running = true
    M.port = port
    vim.notify("gemini-nvim server started on port " .. port)
  else
    M.running = false
    vim.notify("gemini-nvim server failed to start", vim.log.levels.ERROR)
  end
end

return M
