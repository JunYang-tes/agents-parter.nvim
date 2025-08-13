local gemini_server = require('gemini-nvim.server')
local M = {}

---@class GeminiNvimConfig
---@field window_style 'float' | 'side' # Style of the agent window.
---@field side_position 'left' | 'right' # Position of the side window.
---@field float_width_ratio number # Width of the float window as a ratio of the editor width.
---@field float_height_ratio number # Height of the float window as a ratio of the editor height.
---@field agents Agent[] # A list of agents to configure.

---@class Agent
---@field name string # The name of the agent.
---@field program string # The command to run for the agent.
---@field envs table # Environment variables to set for the agent.
---@field toggle_keymap string # The keymap to toggle the agent window.

-- Default configuration, can be overridden by the user in the setup function.
local config = {
  window_style = 'float',  -- 'float' or 'side'
  side_position = 'right', -- 'left' or 'right'
  float_width_ratio = 0.8,
  float_height_ratio = 0.8,
  agents = {
  }
}

-- Holds the state of the running agent sessions, indexed by agent's position in the config table.
local sessions = {}

-- Defines the configuration for the floating window.
local function get_float_win_config()
  local width = math.floor(vim.o.columns * config.float_width_ratio)
  local height = math.floor(vim.o.lines * config.float_height_ratio)
  return {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
  }
end

-- Opens the agent window based on the user's configuration.
local function open_window(session)
  if config.window_style == 'float' then
    session.win = vim.api.nvim_open_win(session.buf, true, get_float_win_config())
  else -- 'side'
    if config.side_position == 'left' then
      vim.cmd('topleft vsplit')
    else
      vim.cmd('botright vsplit')
    end
    vim.api.nvim_win_set_buf(0, session.buf)
    session.win = vim.api.nvim_get_current_win()
    if session.width then
      vim.api.nvim_win_set_width(session.win, session.width)
    end
  end
end

-- The main function for the agent command.
local function toggle_agent_window(agent_index, agent)
  local session = sessions[agent_index]

  -- If the agent window is open
  if session and session.win and vim.api.nvim_win_is_valid(session.win) then
    local current_win = vim.api.nvim_get_current_win()
    if session.win == current_win then
      -- Case 1: Window is open and is the current one, so close it.
      if config.window_style == 'side' then
        session.width = vim.api.nvim_win_get_width(session.win)
      end
      vim.api.nvim_win_close(session.win, false)
      session.win = nil
    else
      -- Case 2: Window is open but not the current one, so focus it.
      vim.api.nvim_set_current_win(session.win)
    end
    return
  end

  -- Case 3: If the buffer exists but the window is hidden, show it again.
  if session and session.buf and vim.api.nvim_buf_is_valid(session.buf) then
    open_window(session)
    return
  end

  -- First run: Create the server, buffer, process, and window.
  local server_addr = vim.v.servername
  if not server_addr or #server_addr == 0 then
    vim.cmd('call serverstart()')
    server_addr = vim.v.servername
  end

  if not server_addr or #server_addr == 0 then
    vim.api.nvim_err_writeln("Error: Could not start or find the Neovim server.")
    return
  end

  sessions[agent_index] = {
    buf = vim.api.nvim_create_buf(false, true),
    win = nil,
  }
  session = sessions[agent_index]
  vim.bo[session.buf].bufhidden = 'hide'

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = session.buf,
    callback = function()
      vim.cmd("startinsert")
    end
  })

  open_window(session)

  local envs = vim.tbl_extend('force', agent.envs or {}, {
    NVIM_LISTEN_ADDRESS = server_addr
  })

  local cmd_to_run = {
    agent.program,
  }

  if agent.program == 'gemini' then
    if not gemini_server.running then
      print("start server")
      gemini_server.start()
    end
    if gemini_server.running then
      print("great")
      local cwd = vim.fn.getcwd()
      envs.GEMINI_CLI_IDE_SERVER_PORT = gemini_server.port
      envs.TERM_PROGRAM = "vscode"
      envs.GEMINI_CLI_IDE_WORKSPACE_PATH = cwd
      table.insert(cmd_to_run, '--ide-mode-feature')
    end
  end
  print(vim.inspect(cmd_to_run))
  print(vim.inspect(envs))

  vim.fn.jobstart(cmd_to_run, {
    term = true,
    env = envs,
    on_exit = function()
      -- Clean up the session state if the process terminates.
      sessions[agent_index] = nil
    end,
  })
end

-- Public setup function for the plugin.
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', config, user_config or {})
  if #config.agents == 0 then
    config.agents = {
      {
        name = 'Gemini',
        program = 'gemini',
        toggle_keymap = user_config.toggle_keymap or '<F3>',
      }
    }
  end

  for i, agent in ipairs(config.agents) do
    local command_name = agent.name
    vim.api.nvim_create_user_command(command_name, function()
      toggle_agent_window(i, agent)
    end, {
      nargs = 0,
      desc = 'Show, hide, or run ' .. command_name
    })

    if agent.toggle_keymap then
      vim.keymap.set('n', agent.toggle_keymap, '<Cmd>' .. command_name .. '<CR>',
        { noremap = true, silent = true, desc = 'Toggle ' .. command_name .. ' Window' })
    end
  end
end

return M
