local M = {}
local log = require('agents-parter.log')

local file_cache = nil
local cache_time = 0
local CACHE_TTL = 5000

local function get_all_files_async(callback)
  local now = vim.loop.now()
  if file_cache and (now - cache_time) < CACHE_TTL then
    callback(file_cache)
    return
  end

  local cmd
  local args
  if vim.fn.executable('fd') == 1 then
    cmd = 'fd'
    args = { '--type', 'f', '--hidden', '--exclude', '.git' }
  elseif vim.fn.executable('rg') == 1 then
    cmd = 'rg'
    args = { '--files', '--hidden', '-g', '!.git' }
  else
    cmd = 'find'
    args = { '.', '-type', 'f', '-not', '-path', '*/.git/*' }
  end

  vim.system({ cmd, unpack(args) }, { cwd = vim.fn.getcwd() }, function(result)
    local files = {}
    if result.code == 0 then
      for line in result.stdout:gmatch('[^\r\n]+') do
        local file = line:gsub('^%./', '')
        table.insert(files, file)
      end
      file_cache = files
      cache_time = vim.loop.now()
    end
    vim.schedule(function()
      callback(files)
    end)
  end)
end

-- Blink.cmp source
M.new = function()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { '@' }
end

function M:get_keyword_pattern()
  return [[@\k*]]
end

function M:get_completions(ctx, callback)
  local cursor_before_line = ctx.line:sub(1, ctx.cursor[2])

  local trigger_match = cursor_before_line:match('@([^%s]*)$')
  if not trigger_match then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    return
  end

  get_all_files_async(function(files)
    local row = ctx.cursor[1] - 1
    local col = ctx.cursor[2]
    local start_col = col - #trigger_match - 1

    local items = {}
    for _, file in ipairs(files) do
      table.insert(items, {
        label = '@' .. file,
        kind = require('blink.cmp.types').CompletionItemKind.File,
        insertText = '@' .. file,
        filterText = '@' .. file,
        sortText = file,
        textEdit = {
          range = {
            start = { line = row, character = start_col },
            ['end'] = { line = row, character = col },
          },
          newText = '@' .. file,
        },
        documentation = {
          kind = 'markdown',
          value = '**File Reference**\n\n```\n' .. file .. '\n```'
        }
      })
    end

    callback({
      is_incomplete_forward = false,
      is_incomplete_backward = false,
      items = items
    })
  end)
end

function M:resolve(item, callback)
  callback(item)
end

return M
