**注意**

建议将此插件与 [neovim-ide-companion](https://github.com/JunYang-tes/neovim-ide-companion) 一起使用。
```bash
bun i -g neovim-ide-companion
```
如果您使用 npm
```bash
npm i -g neovim-ide-companion 
# 使用 npm 全局安装可能需要 root 权限。
sudo npm i -g neovim-gemini-companion 
```


# gemini.nvim

[![Mentioned in Awesome Gemini CLI](https://awesome.re/mentioned-badge.svg)](https://github.com/Piebald-AI/awesome-gemini-cli)

一个非官方的 Neovim 插件，用于在持久终端窗口中与 Google Gemini CLI 交互。

[![asciicast](https://asciinema.org/a/qCrA52b4s5lfnjQJRPc3Cnton.svg)](https://asciinema.org/a/qCrA52b4s5lfnjQJRPc3Cnton)


## 功能特性

- 在后台持久运行 `gemini` / `claude` 终端会话。
- 通过单个命令或快捷键切换终端窗口的可见性。
- 可选择浮动窗口或垂直侧边栏。
- 高度可配置的窗口几何形状和快捷键。
- 与 Neovim 原生的 `:checkhealth` 系统集成。

## 环境要求

- Neovim >= 0.8
- [Google Gemini CLI](https://github.com/google/gemini-cli) (>= 0.1.19) 或 claude code
- Node.js >= 22


## 安装方法

以下是使用 `lazy.nvim` 的示例。由于此插件目前是 monorepo 的一部分，您需要将 `dir` 指向包的本地路径。

```lua
-- lazy.nvim 配置
{
  'JunYang-tes/agents-parter.nvim',

  config = function()
    require('agents-parter').setup({
      -- 您的配置放在这里
    })
  end,
}
```

## 配置选项

调用 `setup` 函数来配置插件。以下是所有可用选项及其默认值：

```lua
-- init.lua

require('agents-parter').setup({
  -- 要打开的窗口样式。
  -- 可以是 'float' 或 'side'。
  window_style = 'float',

  -- 对于 `window_style = 'side'`。
  -- 可以是 'left' 或 'right'。
  side_position = 'right',

  -- 对于 `window_style = 'float'`。
  -- 值为编辑器尺寸的百分比。
  float_width_ratio = 0.8,
  float_height_ratio = 0.8,

  -- 要配置的代理列表。
  agents = {
    {
      -- 代理的名称。将用于用户命令。
      -- 例如 :Gemini
      name = 'Gemini',
      -- 要运行的代理命令。
      program = 'gemini',
      -- 要传递给程序的环境变量。
      envs = {},
      -- 要传递给程序的参数。
      -- 例如 {'-m','gemini-2.5-pro'}
      params = {},
      -- 切换代理窗口的快捷键。
      toggle_keymap = '<F3>',
    }
  }
})
```

## 使用方法

- `:Gemini`: 切换 Gemini 终端窗口（打开、隐藏或显示）。
- 按 `<F3>`（或您配置的快捷键）执行相同操作。
- `:checkhealth gemini`: 检查依赖项（`gemini` 可执行文件、Node.js 版本等）。

### 终端模式说明（针对不熟悉终端模式的用户）：

- 在普通模式下，按 I 进入终端模式，您可以与 Gemini 交互。

- 在终端模式下，按 Ctrl+N 或 Ctrl+\ 返回普通模式，然后可以按 <F3> 关闭 Gemini 窗口。