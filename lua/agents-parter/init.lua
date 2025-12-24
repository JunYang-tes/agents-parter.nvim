local gemini_server = require('agents-parter.server')
local config_mod = require('agents-parter.config')
local agent_mod = require('agents-parter.agent')
local M = {}

-- Public setup function for the plugin.
function M.setup(user_config)
  local config = config_mod.setup(user_config)

  vim.api.nvim_create_user_command("AgentsParterPrompt", function()
    agent_mod.handle_prompt_with_selection()
  end, {
    range = true,
    desc = 'Prompt agent with selected text'
  })

  vim.api.nvim_create_user_command("AgentsParterServerStatus", function()
    gemini_server.show_status()
  end, {
    nargs = 0,
    desc = 'Show agents parter server status'
  })

  -- Keymap to trigger the prompt
  if config.prompt_keymap then
    vim.keymap.set('v', config.prompt_keymap, ':AgentsParterPrompt<CR>', {
      noremap = true,
      silent = true,
      desc = 'Ask with Selection'
    })
  end

  for i, agent in ipairs(config.agents) do
    local command_name = agent.name
    vim.api.nvim_create_user_command(command_name, function()
      agent_mod.toggle_agent_window(i, agent)
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