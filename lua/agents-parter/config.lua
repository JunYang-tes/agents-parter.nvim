local M = {}

---@class Agent
---@field name string # The name of the agent.
---@field program string # The command to run for the agent.
---@field params string[] # Extra params for the agent program.
---@field envs table # Environment variables to set for the agent.
---@field toggle_keymap string # The keymap to toggle the agent window.

---@class GeminiNvimConfig
---@field window_style 'float' | 'side' # Style of the agent window.
---@field side_position 'left' | 'right' # Position of the side window.
---@field float_width_ratio number # Width of the float window as a ratio of the editor width.
---@field float_height_ratio number # Height of the float window as a ratio of the editor height.
---@field agents Agent[] # A list of agents to configure.

M.defaults = {
  window_style = 'float',  -- 'float' or 'side'
  side_position = 'right', -- 'left' or 'right'
  float_width_ratio = 0.8,
  float_height_ratio = 0.8,
  agents = {}
}

M.options = {}

function M.setup(user_config)
  M.options = vim.tbl_deep_extend('force', M.defaults, user_config or {})
  if #M.options.agents == 0 then
    M.options.agents = {
      {
        name = 'Gemini',
        program = 'gemini',
        toggle_keymap = user_config.toggle_keymap or '<F3>',
      }
    }
  end
  return M.options
end

return M
