# Neovim API Patterns

## Overview
Neovim exposes Lua APIs through the `vim` global object. Understanding these APIs is essential for configuration development.

## Core API Namespaces

### vim.api - Neovim API Functions
Direct bindings to Neovim's C API functions.

```lua
-- Buffer operations
vim.api.nvim_buf_get_lines(bufnr, start, end_, strict)
vim.api.nvim_buf_set_lines(bufnr, start, end_, strict, lines)
vim.api.nvim_buf_get_name(bufnr)
vim.api.nvim_buf_set_option(bufnr, name, value)

-- Window operations
vim.api.nvim_win_get_cursor(winnr)
vim.api.nvim_win_set_cursor(winnr, {row, col})
vim.api.nvim_win_get_buf(winnr)
vim.api.nvim_win_get_width(winnr)

-- Global operations
vim.api.nvim_get_current_buf()
vim.api.nvim_get_current_win()
vim.api.nvim_command(command)
vim.api.nvim_exec2(lua, opts)

-- Autocommands
vim.api.nvim_create_autocmd(event, opts)
vim.api.nvim_create_augroup(name, opts)

-- Keymaps
vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)

-- Highlights
vim.api.nvim_set_hl(ns_id, name, val)
vim.api.nvim_get_hl(ns_id, opts)
```

### vim.fn - Vimscript Functions
Access to Vimscript builtin and user-defined functions.

```lua
-- File operations
vim.fn.expand('%:p')           -- Expand current file path
vim.fn.fnamemodify(path, mod)  -- Modify filename
vim.fn.filereadable(path)      -- Check if file exists
vim.fn.glob(pattern, ...)      -- Glob pattern matching
vim.fn.readfile(path)          -- Read file as lines

-- Buffer/window
vim.fn.bufnr('%')              -- Current buffer number
vim.fn.winnr()                 -- Current window number
vim.fn.line('.')               -- Current line number
vim.fn.col('.')                -- Current column number

-- String manipulation
vim.fn.substitute(str, pat, sub, flags)
vim.fn.trim(str)
vim.fn.split(str, sep)
vim.fn.join(list, sep)

-- System interaction
vim.fn.system(cmd)             -- Execute shell command
vim.fn.executable(name)        -- Check if executable exists
vim.fn.environ()               -- Get environment variables
```

### vim.opt - Option Management
Type-safe Lua interface for Vim options.

```lua
-- Set options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- List options (append, prepend, remove)
vim.opt.path:append("**")
vim.opt.formatoptions:remove("o")

-- Get option value
local tabstop = vim.opt.tabstop:get()

-- Local options
vim.opt_local.spell = true
vim.opt_global.clipboard = "unnamedplus"
```

### vim.keymap - Keymap API
Modern keymap API with Lua callback support.

```lua
-- Basic keymap
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })

-- With Lua callback
vim.keymap.set("n", "<leader>f", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })

-- Multiple modes
vim.keymap.set({"n", "v"}, "<leader>y", '"+y', { desc = "Yank to clipboard" })

-- Buffer-local
vim.keymap.set("n", "<leader>t", function()
  vim.cmd("terminal")
end, { buffer = true, desc = "Open terminal" })

-- Delete keymap
vim.keymap.del("n", "<leader>old")
```

## Common Patterns

### Safe Module Loading
```lua
local ok, module = pcall(require, "module-name")
if not ok then
  vim.notify("Module not found: module-name", vim.log.levels.WARN)
  return
end
```

### Autocommand Groups
```lua
local group = vim.api.nvim_create_augroup("MyGroup", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = "*.lua",
  callback = function()
    vim.lsp.buf.format()
  end,
})
```

### User Commands
```lua
vim.api.nvim_create_user_command("MyCommand", function(opts)
  print(opts.args)
end, {
  nargs = "*",
  desc = "My custom command",
})
```

### Notifications
```lua
vim.notify("Info message", vim.log.levels.INFO)
vim.notify("Warning message", vim.log.levels.WARN)
vim.notify("Error message", vim.log.levels.ERROR)
```

## Best Practices

1. **Use vim.keymap over vim.api.nvim_set_keymap** - Cleaner syntax, Lua callback support
2. **Use vim.opt over vim.o** - Type-safe, better list operations
3. **Always use pcall for external modules** - Graceful degradation
4. **Create autocommand groups** - Prevents duplicate autocommands
5. **Add descriptions to keymaps** - Improves discoverability with which-key
