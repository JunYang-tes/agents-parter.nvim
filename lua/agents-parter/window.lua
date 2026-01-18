local M = {}

local original_opts = nil

function M.is_agent_window(win)
  if not win or not vim.api.nvim_win_is_valid(win) then return false end
  local buf = vim.api.nvim_win_get_buf(win)
  local ok, val = pcall(vim.api.nvim_buf_get_var, buf, "is_agent_term_buffer")
  return ok and val == true
end

-- Saves and applies window options for the agent window.
function M.apply_win_options(win)
  if not win or not vim.api.nvim_win_is_valid(win) then return end
  if original_opts == nil then
    original_opts = {
      statuscolumn = vim.wo[win].statuscolumn,
      number = vim.wo[win].number,
      relativenumber = vim.wo[win].relativenumber,
      signcolumn = vim.wo[win].signcolumn,
      foldcolumn = vim.wo[win].foldcolumn,
    }
  end

  vim.wo[win].statuscolumn = ""
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
end

-- Restores window options when the agent buffer is no longer in the window.
function M.restore_win_options(win)
  if original_opts ~= nil then
    for opt, val in pairs(original_opts) do
      vim.wo[win][opt] = val
    end
  end
end

function M.setup_global_autocmds(augroup)
  -- Fix window option inheritance for new windows/tabs created from agent windows.
  vim.api.nvim_create_autocmd("TabNew", {
    group = augroup,
    callback = function()
      vim.schedule(function()
        local win = vim.api.nvim_get_current_win()
        local config = vim.api.nvim_win_get_config(win)

        if not M.is_agent_window(win) and config.relative == "" then
          -- in case of window options is inherited for a agent window
          M.restore_win_options(win)
        end
      end)
    end
  })
end

function M.setup_buffer_autocmds(augroup, bufnr)
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      M.apply_win_options(vim.api.nvim_get_current_win())
    end
  })

  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      M.restore_win_options(vim.api.nvim_get_current_win())
    end
  })
end

return M
