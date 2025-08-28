local M = {}

function M.check()
  vim.health.start("Checking gemini.nvim")

  -- Check for the 'gemini' executable
  if vim.fn.executable('gemini') == 1 then
    vim.health.ok("`gemini` executable is found in PATH.")
  else
    vim.health.error("`gemini` executable not found.", {
      "Please install the Gemini CLI.",
      "See https://github.com/google/gemini-cli for installation instructions."
    })
  end

  -- Check for Node.js version
  if vim.fn.executable('node') == 1 then
    local version_str = vim.fn.system('node --version')
    local major_version = tonumber(string.match(version_str, "v(%d+)"))
    if major_version then
      if major_version >= 22 then
        vim.health.ok("Node.js version is " .. version_str:gsub('\n', '') .. " (>= 22).")
      else
        vim.health.warn("Node.js version is " .. version_str:gsub('\n', '') .. ". Version 22 or higher is recommended.")
      end
    else
      vim.health.warn("Could not parse Node.js version string: " .. version_str:gsub('\n', ''))
    end
  else
    vim.health.error("`node` executable not found. Node.js is required.")
  end

  -- Check for 'neovim-ide-port' executable
  if vim.fn.executable('neovim-ide-port') == 1 then
    vim.health.ok("`neovim-ide-port` executable is found in PATH.")
  else
    vim.health.error("`neovim-ide-port` executable not found.", {
      "Please install neovim-gemini-companion.",
      "See https://github.com/JunYang-tes/neovim-gemini-companion for installation instructions."
    })
  end

  -- Check for 'neovim-ide-companion' executable
  if vim.fn.executable('neovim-ide-companion') == 1 then
    vim.health.ok("`neovim-ide-companion` executable is found in PATH.")
  else
    vim.health.error("`neovim-ide-companion` executable not found.", {
      "Please install neovim-ide-companion.",
      "See https://github.com/JunYang-tes/neovim-ide-companion for installation instructions."
    })
  end
end

return M
