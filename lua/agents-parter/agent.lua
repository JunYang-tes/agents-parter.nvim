local gemini_server = require('agents-parter.server')
local config_mod = require('agents-parter.config')
local M = {}

-- Holds the state of the running agent sessions, indexed by agent's position in the config table.
local sessions = {}
local last_agent_index = nil

-- Defines the configuration for the floating window.
local function get_float_win_config()
  local config = config_mod.options
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
  local config = config_mod.options
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
function M.toggle_agent_window(agent_index, agent)
  local config = config_mod.options
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
      last_agent_index = agent_index
    end
    return
  end

  -- Case 3: If the buffer exists but the window is hidden, show it again.
  if session and session.buf and vim.api.nvim_buf_is_valid(session.buf) then
    open_window(session)
    last_agent_index = agent_index
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
    submit_key = agent.submit_key,
  }
  session = sessions[agent_index]
  vim.bo[session.buf].bufhidden = 'hide'

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = session.buf,
    callback = function()
      vim.cmd("startinsert")
      -- Set buffer variable with current timestamp
      vim.api.nvim_buf_set_var(session.buf, "neovim-ide-companion-ts", tostring(os.time()))
      last_agent_index = agent_index
    end
  })

  open_window(session)
  last_agent_index = agent_index

  local envs = vim.tbl_extend('force', agent.envs or {},
    {
    NVIM_LISTEN_ADDRESS = server_addr
  })

  local cmd_to_run = {
    agent.program,
  }

  if agent.params then
    for _, param in ipairs(agent.params) do
      table.insert(cmd_to_run, param)
    end
  end

  if agent.program == 'gemini' or agent.program == 'qwen'
    or agent.program == 'claude'
  then
    if gemini_server.status ~= 'RUNNING' then
      gemini_server.start()
    end
    if gemini_server.status == 'RUNNING' then
      if agent.program == 'gemini' then
        local cwd = vim.fn.getcwd()
        envs.GEMINI_CLI_IDE_SERVER_PORT = gemini_server.port
        envs.TERM_PROGRAM = "vscode"
        envs.GEMINI_CLI_IDE_WORKSPACE_PATH = cwd
        if agent.program == 'qwen' then
          table.insert(cmd_to_run, '--ide-mode')
        end
      elseif agent.program == 'claude' then
        envs.CLAUDE_CODE_SSE_PORT = gemini_server.port
        table.insert(cmd_to_run, "--ide")
      end
    end
  end

  session.job_id = vim.fn.jobstart(cmd_to_run, {
    term = true,
    env = envs,
    on_exit = function()
      -- Clean up the session state if the process terminates.
      sessions[agent_index] = nil
      if last_agent_index == agent_index then
        last_agent_index = nil
      end
    end,
  })
end

function M.get_last_agent()
  if last_agent_index and sessions[last_agent_index] then
    return sessions[last_agent_index]
  end
  -- If last_agent_index is not set, find the first available session
  for _, s in pairs(sessions) do
    return s
  end
  return nil
end

function M.send_to_agent(text)
  local session = M.get_last_agent()
  if not session or not session.job_id then
    vim.notify("No active agent session found", vim.log.levels.WARN)
    return false
  end

  -- Focus or open the agent window first
  if session.win and vim.api.nvim_win_is_valid(session.win) then
    vim.api.nvim_set_current_win(session.win)
  else
    open_window(session)
  end

  -- Use schedule to ensure the focus switch and mode change are processed
  vim.schedule(function()
    -- Ensure we are in terminal mode (insert mode in terminal buffer)
    vim.cmd("startinsert")
    
    -- Send the actual text content via chan_send to the job's stdin
    vim.api.nvim_chan_send(session.job_id, text)

    -- Send the submit key via feedkeys with 't' flag
    local submit_key = session.submit_key or "<CR>"
    local keys = vim.api.nvim_replace_termcodes(submit_key, true, false, true)
    vim.api.nvim_feedkeys(keys, 't', false)
  end)

  return true
end

function M.handle_prompt_with_selection()
  local prompt_mod = require('agents-parter.prompt')
  
  -- Ensure we have the latest visual marks
  -- If we are in visual mode, exit it to update '< and '> marks
  local mode = vim.api.nvim_get_mode().mode
  if mode:match("[vV\22]") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'x', true)
  end

  local _start = vim.api.nvim_buf_get_mark(0, "<")
  local _end = vim.api.nvim_buf_get_mark(0, ">")
  
  local selected_text = ""
  if _start[1] > 0 and _end[1] > 0 then
    -- Use pcall because get_text might fail if marks are invalid or buffer changed
    local ok, lines = pcall(vim.api.nvim_buf_get_text, 0, _start[1] - 1, _start[2], _end[1] - 1, _end[2] + 1, {})
    if ok then
      selected_text = table.concat(lines, "\n")
    end
  end

  prompt_mod.open_prompt(function(user_input)
    local final_text = user_input
    if selected_text ~= "" then
      final_text = user_input .. "\n\nSelected Context:\n```\n" .. selected_text .. "\n```"
    end
    M.send_to_agent(final_text)
  end)
end

function M.is_any_agent_window_open()
  for _, session in pairs(sessions) do
    if session.win and vim.api.nvim_win_is_valid(session.win) then
      return true
    end
  end
  return false
end

return M
