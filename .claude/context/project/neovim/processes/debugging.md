# Debugging in Neovim

## Basic Debugging

### Print Debugging
```lua
-- Simple print (shows in :messages)
print("Debug:", vim.inspect(value))

-- With notification
vim.notify("Debug: " .. vim.inspect(value), vim.log.levels.DEBUG)

-- Pretty print table
vim.print(some_table)  -- Neovim 0.9+
print(vim.inspect(some_table))  -- All versions
```

### View Messages
```vim
:messages           " Show recent messages
:messages clear     " Clear message history
```

### Check Loaded Modules
```lua
-- Check if module is loaded
print(package.loaded["my-plugin"] ~= nil)

-- List all loaded modules
for name, _ in pairs(package.loaded) do
  if name:match("^my%-plugin") then
    print(name)
  end
end

-- Force reload module
package.loaded["my-plugin"] = nil
require("my-plugin")
```

## Logging

### vim.notify Levels
```lua
vim.notify("Info message", vim.log.levels.INFO)
vim.notify("Warning", vim.log.levels.WARN)
vim.notify("Error", vim.log.levels.ERROR)
vim.notify("Debug", vim.log.levels.DEBUG)
vim.notify("Trace", vim.log.levels.TRACE)
```

### Custom Logger
```lua
local M = {}

M.log_level = vim.log.levels.INFO

function M.debug(msg)
  if M.log_level <= vim.log.levels.DEBUG then
    vim.notify("[my-plugin] " .. msg, vim.log.levels.DEBUG)
  end
end

function M.info(msg)
  if M.log_level <= vim.log.levels.INFO then
    vim.notify("[my-plugin] " .. msg, vim.log.levels.INFO)
  end
end

function M.error(msg)
  vim.notify("[my-plugin] " .. msg, vim.log.levels.ERROR)
end

return M
```

### File Logging
```lua
local function log_to_file(msg)
  local log_file = vim.fn.stdpath("cache") .. "/my-plugin.log"
  local f = io.open(log_file, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
    f:close()
  end
end
```

## LSP Debugging

### Enable LSP Logging
```lua
vim.lsp.set_log_level("debug")
```

### View LSP Log
```vim
:LspLog
" or
:edit ~/.local/state/nvim/lsp.log
```

### Check Active Clients
```vim
:LspInfo
```

### Debug LSP Handlers
```lua
-- Wrap handler to debug
local original_handler = vim.lsp.handlers["textDocument/hover"]
vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
  print("Hover result:", vim.inspect(result))
  return original_handler(err, result, ctx, config)
end
```

## DAP (Debug Adapter Protocol)

### Setup nvim-dap
```lua
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup()

    -- Auto open/close DAP UI
    dap.listeners.after.event_initialized["dapui"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui"] = function()
      dapui.close()
    end
  end,
}
```

### Keymaps
```lua
vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP Continue" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP Step Over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP Step Into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP Step Out" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
```

### Lua Debugging (one-small-step-for-vimkind)
```lua
-- Setup osv for Lua debugging
local dap = require("dap")

dap.configurations.lua = {
  {
    type = "nlua",
    request = "attach",
    name = "Attach to running Neovim instance",
  },
}

dap.adapters.nlua = function(callback, config)
  callback({
    type = "server",
    host = config.host or "127.0.0.1",
    port = config.port or 8086,
  })
end

-- In Neovim you want to debug:
require("osv").launch({ port = 8086 })
```

## Startup Profiling

### Built-in Startup Time
```bash
nvim --startuptime startup.log
```

### Lazy.nvim Profiling
```vim
:Lazy profile
```

### Manual Timing
```lua
local start = vim.loop.hrtime()
-- Operation
local elapsed = (vim.loop.hrtime() - start) / 1e6
print(string.format("Elapsed: %.2fms", elapsed))
```

### Profile Block
```lua
local function profile(name, fn)
  local start = vim.loop.hrtime()
  local result = fn()
  local elapsed = (vim.loop.hrtime() - start) / 1e6
  vim.notify(string.format("%s: %.2fms", name, elapsed))
  return result
end

-- Usage
profile("load_plugins", function()
  require("my-plugin").setup()
end)
```

## Health Checks

### Create Health Check
```lua
-- lua/my-plugin/health.lua
local M = {}

function M.check()
  vim.health.start("my-plugin")

  -- Check dependency
  if vim.fn.executable("rg") == 1 then
    vim.health.ok("ripgrep is installed")
  else
    vim.health.warn("ripgrep not found, some features may be slow")
  end

  -- Check Neovim version
  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim version is compatible")
  else
    vim.health.error("Neovim 0.9+ required")
  end

  -- Check configuration
  local config = require("my-plugin").config
  if config.enabled then
    vim.health.ok("Plugin is enabled")
  else
    vim.health.info("Plugin is disabled")
  end
end

return M
```

### Run Health Check
```vim
:checkhealth my-plugin
```

## Common Debug Patterns

### Trace Function Calls
```lua
local function trace(fn, name)
  return function(...)
    print("ENTER:", name)
    local result = { fn(...) }
    print("EXIT:", name, "->", vim.inspect(result))
    return unpack(result)
  end
end

-- Usage
M.process = trace(M.process, "process")
```

### Debug Autocommands
```lua
vim.api.nvim_create_autocmd("*", {
  callback = function(args)
    print("Event:", args.event, "File:", args.file or "none")
  end,
})
```

### Inspect Highlight Groups
```vim
:Inspect            " Show highlight under cursor (0.9+)
:hi                 " List all highlight groups
:verbose hi Normal  " Show where highlight was set
```

### Check Mappings
```vim
:map <leader>f      " Show mapping
:verbose map <leader>f  " Show where mapping was defined
```

## Troubleshooting

### Common Issues
1. **Plugin not loading**: Check `:Lazy` for errors
2. **Keymap not working**: Check `:verbose map <key>`
3. **LSP not attaching**: Check `:LspInfo` and `:LspLog`
4. **Slow startup**: Run `:Lazy profile`
5. **Treesitter errors**: `:checkhealth nvim-treesitter`

### Reset State
```lua
-- Clear plugin cache
package.loaded["my-plugin"] = nil

-- Clear Lua module cache
for name, _ in pairs(package.loaded) do
  if name:match("^my%-plugin") then
    package.loaded[name] = nil
  end
end
```
