# Lua Patterns for Neovim

## Module Patterns

### Standard Module Structure
```lua
-- lua/neotex/plugins/category/plugin-name.lua
local M = {}

-- Private function (local)
local function private_helper()
  return "helper result"
end

-- Public function (exported)
function M.public_function()
  return private_helper()
end

-- Setup function (common pattern)
function M.setup(opts)
  opts = opts or {}
  -- Initialize module with options
end

return M
```

### Plugin Spec Module
```lua
-- lazy.nvim plugin specification
return {
  "author/plugin-name",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    setting = "value",
  },
  config = function(_, opts)
    require("plugin-name").setup(opts)
  end,
}
```

### Namespace Module
```lua
-- lua/neotex/core/init.lua
return {
  utils = require("neotex.core.utils"),
  health = require("neotex.core.health"),
  -- other submodules
}
```

## Metatable Patterns

### Object-Oriented Pattern
```lua
local Object = {}
Object.__index = Object

function Object:new(opts)
  local instance = setmetatable({}, self)
  instance.name = opts.name or "default"
  return instance
end

function Object:method()
  return self.name
end

-- Usage
local obj = Object:new({ name = "test" })
print(obj:method())  -- "test"
```

### Callable Table
```lua
local Callable = setmetatable({}, {
  __call = function(self, ...)
    return self.invoke(...)
  end,
})

function Callable.invoke(arg)
  return arg * 2
end

-- Usage
print(Callable(5))  -- 10
```

### Default Values Pattern
```lua
local defaults = {
  enabled = true,
  timeout = 1000,
}

local config = setmetatable({}, {
  __index = defaults,
})

-- Access uses default if not set
print(config.enabled)  -- true
config.timeout = 500   -- Override default
```

## Iterator Patterns

### Pairs/IPairs
```lua
-- ipairs for arrays (1-indexed, sequential)
local list = { "a", "b", "c" }
for i, v in ipairs(list) do
  print(i, v)
end

-- pairs for tables (unordered)
local dict = { a = 1, b = 2 }
for k, v in pairs(dict) do
  print(k, v)
end
```

### Custom Iterator
```lua
local function values(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

for v in values({ "x", "y", "z" }) do
  print(v)
end
```

### Filter/Map Pattern
```lua
-- Filter
local function filter(t, predicate)
  local result = {}
  for _, v in ipairs(t) do
    if predicate(v) then
      table.insert(result, v)
    end
  end
  return result
end

-- Map
local function map(t, fn)
  local result = {}
  for i, v in ipairs(t) do
    result[i] = fn(v)
  end
  return result
end
```

## Error Handling Idioms

### pcall Pattern
```lua
local ok, result = pcall(function()
  -- Potentially failing code
  return require("missing-module")
end)

if not ok then
  vim.notify("Error: " .. result, vim.log.levels.ERROR)
  return nil
end
```

### xpcall with Traceback
```lua
local ok, result = xpcall(function()
  error("Something went wrong")
end, debug.traceback)

if not ok then
  print(result)  -- Includes full stack trace
end
```

### Protected Call Wrapper
```lua
local function safe_require(module_name)
  local ok, module = pcall(require, module_name)
  if not ok then
    vim.notify("Failed to load: " .. module_name, vim.log.levels.WARN)
    return nil
  end
  return module
end
```

### Assert with Message
```lua
local function validate_config(config)
  assert(config.name, "config.name is required")
  assert(type(config.timeout) == "number", "config.timeout must be a number")
end
```

## String Patterns

### Pattern Matching
```lua
local str = "Hello World"

-- match: returns captured group or nil
local word = str:match("(%w+)")  -- "Hello"

-- find: returns start, end, captures
local s, e = str:find("World")  -- 7, 11

-- gsub: global substitution
local result = str:gsub("World", "Neovim")  -- "Hello Neovim"

-- gmatch: iterator over matches
for word in str:gmatch("%w+") do
  print(word)
end
```

### Common Patterns
```lua
"%d+"     -- One or more digits
"%w+"     -- One or more word characters
"%s+"     -- One or more whitespace
"[^/]+"   -- One or more non-slash characters
"%.lua$"  -- Ends with .lua
"^#"      -- Starts with #
```

## Table Utilities

### vim.tbl_extend
```lua
-- Merge tables (later tables win)
local defaults = { a = 1, b = 2 }
local overrides = { b = 3, c = 4 }
local merged = vim.tbl_extend("force", defaults, overrides)
-- { a = 1, b = 3, c = 4 }
```

### vim.tbl_deep_extend
```lua
-- Deep merge for nested tables
local defaults = { ui = { border = "single" } }
local overrides = { ui = { icons = true } }
local merged = vim.tbl_deep_extend("force", defaults, overrides)
-- { ui = { border = "single", icons = true } }
```

### vim.list_extend
```lua
-- Extend array
local list = { 1, 2, 3 }
vim.list_extend(list, { 4, 5 })
-- { 1, 2, 3, 4, 5 }
```

### vim.tbl_contains
```lua
local list = { "a", "b", "c" }
if vim.tbl_contains(list, "b") then
  print("found")
end
```
