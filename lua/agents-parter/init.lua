local gemini_server = require('agents-parter.server')
local config_mod = require('agents-parter.config')
local agent_mod = require('agents-parter.agent')
local log = require('agents-parter.log')
local M = {}

-- Public setup function for the plugin.
function M.setup(user_config)
  log.info("Setting up agents-parter")
  local config = config_mod.setup(user_config)

  -- Register file reference source for blink.cmp
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    local provider_ok, err = pcall(function()
      blink.add_source_provider('file_reference', {
        name = 'AgentsParterFileReference',
        module = 'agents-parter.file_reference_source',
        enabled = true,
        timeout_ms = 3000,
        score_offset = 5,
      })
      log.info("File reference source registered successfully")
    end)

    if not provider_ok then
      log.error("Failed to register file_reference source: " .. tostring(err))
    end
  end

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
