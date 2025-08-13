>**NOTE**
>
>It is recommended to use this plugin along with [neovim-gemini-companion](https://github.com/JunYang-tes/neovim-gemini-companion).
>```bash
>bun i -g neovim-gemini-companion
>```
>If you are using npm
>```bash
>npm i -g neovim-gemini-companion 
># Installing globally with npm may require root privileges.
>sudo npm i -g neovim-gemini-companion 
>```


# gemini.nvim

An unofficial Neovim plugin to interact with the Google Gemini CLI within a persistent terminal window.

[![asciicast](https://asciinema.org/a/qCrA52b4s5lfnjQJRPc3Cnton.svg)](https://asciinema.org/a/qCrA52b4s5lfnjQJRPc3Cnton)



## Features

- Run the `gemini` CLI in a terminal session that persists in the background.
- Toggle the terminal window's visibility with a single command or keymap.
- Choose between a floating window or a vertical side panel.
- Highly configurable window geometry and keymaps.
- Integrates with Neovim's native `:checkhealth` system.

## Requirements

- Neovim >= 0.8
- [Google Gemini CLI](https://github.com/google/gemini-cli) (>= 0.1.18-nightly.250812.26fe587b)
- Node.js >= 22



## Installation

Here is an example using `lazy.nvim`. As this plugin is currently part of a monorepo, you would need to point the `dir` to the local path of the package.

```lua
-- lazy.nvim spec
{
  'JunYang-tes/gemini-nvim',

  config = function()
    require('gemini-nvim').setup({
      -- Your configuration goes here
    })
  end,
}
```

## Configuration

Call the `setup` function to configure the plugin. Here are all the available options with their default values:

```lua
-- init.lua

require('gemini-nvim').setup({
  -- The style of the window to open.
  -- Can be 'float' or 'side'.
  window_style = 'float',

  -- For `window_style = 'side'`.
  -- Can be 'left' or 'right'.
  side_position = 'right',

  -- For `window_style = 'float'`.
  -- Values are a percentage of the editor's dimensions.
  float_width_ratio = 0.8,
  float_height_ratio = 0.8,

  -- A list of agents to configure.
  agents = {
    {
      -- The name of the agent. This will be used for the user command.
      -- e.g. :Gemini
      name = 'Gemini',
      -- The command to run for the agent.
      program = 'gemini',
      -- The keymap to toggle the agent window.
      toggle_keymap = '<F3>',
    }
  }
})
```

## Usage

- `:Gemini`: Toggles the Gemini terminal window (opens, hides, or shows it).
- Press `<F3>` (or your configured keymap) to do the same.
- `:checkhealth gemini`: Checks for dependencies (`gemini` executable, Node.js version, etc.).

### Additional explanation for those unfamiliar with Terminal Mode:

- In Normal Mode, press I to enter Terminal Mode, where you can interact with Gemini.

- In Terminal Mode, press Ctrl+N or Ctrl+\ to return to Normal Mode, where you can press <F3> to close the Gemini window.
