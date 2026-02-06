# Neovim Lua Patterns

**Scope**: Lua idioms and patterns for Neovim configuration

## Module Structure

```lua
-- lua/plugins/my-plugin.lua
local M = {}

-- Configuration
M.config = function()
  require('my-plugin').setup({
    -- options
  })
end

return M
```

## Plugin Specification (lazy.nvim)

```lua
-- Minimal spec
{ 'owner/repo', config = true }

-- With dependencies
{
  'owner/repo',
  dependencies = { 'dep1', 'dep2' },
  config = function()
    require('plugin').setup({
      setting = value,
    })
  end,
}

-- With lazy loading
{
  'owner/repo',
  event = 'VeryLazy',
  keys = {
    { '<leader>f', '<cmd>PluginCommand<cr>', desc = 'Plugin function' },
  },
}
```

## Keymaps

```lua
-- Standard pattern
vim.keymap.set('n', '<leader>f', '<cmd>Telescope find_files<cr>', { desc = 'Find files' })

-- With function
vim.keymap.set('n', '<leader>x', function()
  -- do something
end, { desc = 'Custom function' })

-- Which-key registration (if using which-key)
local wk = require('which-key')
wk.register({
  f = { name = 'Find', f = { '<cmd>Telescope find_files<cr>', 'Find files' } },
}, { prefix = '<leader>' })
```

## Autocommands

```lua
-- Create augroup
local augroup = vim.api.nvim_create_augroup('MyGroup', { clear = true })

-- Define autocmd
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'lua',
  callback = function()
    -- do something
  end,
})
```

## Options

```lua
-- Set options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Buffer-local options
vim.bo.filetype = 'lua'

-- Window-local options
vim.wo.cursorline = true
```

## Key Principles

- Use `vim.opt` for global options
- Use lazy.nvim for plugin management
- Organize plugins in `lua/plugins/` directory
- Keep plugin specs focused and minimal
- Use descriptive keymap descriptions
- Group related autocommands in augroups
