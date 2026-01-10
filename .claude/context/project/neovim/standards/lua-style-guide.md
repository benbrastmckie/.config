# Lua Style Guide for Neovim

## Indentation and Spacing

### Indentation
- **2 spaces** per indentation level
- **No tabs** - use `expandtab`
- Consistent indentation throughout file

```lua
-- Correct
local function example()
  if condition then
    do_something()
  end
end

-- Incorrect (4 spaces)
local function example()
    if condition then
        do_something()
    end
end
```

### Line Length
- **~100 characters** soft limit
- Break long lines at logical points
- Prefer readability over strict limits

```lua
-- Break long function calls
local result = some_function(
  first_argument,
  second_argument,
  third_argument
)

-- Break long conditionals
if condition_one
  and condition_two
  and condition_three
then
  do_something()
end
```

### Blank Lines
- One blank line between functions
- One blank line between logical sections
- No trailing blank lines at end of file

## Naming Conventions

### Variables and Functions
- **snake_case** for variables and functions
- Descriptive names over abbreviations
- Prefix private variables with `_` (optional)

```lua
local current_buffer = vim.api.nvim_get_current_buf()
local is_valid = validate_input(data)

-- Private (internal use)
local _internal_state = {}
```

### Constants
- **UPPER_SNAKE_CASE** for constants
- Define at module level

```lua
local MAX_BUFFER_SIZE = 1000
local DEFAULT_TIMEOUT = 5000
```

### Modules
- **lowercase** module names
- **hyphen-separated** for multi-word files
- **snake_case** for internal references

```lua
-- File: lua/neotex/plugins/text/markdown-preview.lua
-- Require as: require("neotex.plugins.text.markdown-preview")
```

## Module Structure

### Standard Layout
```lua
-- 1. Imports at top
local utils = require("neotex.core.utils")
local api = vim.api

-- 2. Constants
local DEFAULT_OPTIONS = {
  enabled = true,
}

-- 3. Module table
local M = {}

-- 4. Private functions
local function private_helper()
  -- implementation
end

-- 5. Public functions
function M.public_method()
  return private_helper()
end

-- 6. Setup function (if applicable)
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", DEFAULT_OPTIONS, opts or {})
  -- initialization
end

-- 7. Return module
return M
```

### Plugin Spec Layout
```lua
return {
  "author/plugin-name",
  dependencies = { "dep/plugin" },
  event = "VeryLazy",
  opts = {},
  config = function(_, opts)
    require("plugin").setup(opts)
  end,
}
```

## Function Style

### Local Functions
- Use `local function` for private functions
- Define before use

```lua
local function helper()
  return "result"
end

local function main()
  return helper()
end
```

### Function Parameters
- Use named parameter tables for functions with > 3 parameters
- Document expected table keys

```lua
-- Too many positional arguments
local function bad(a, b, c, d, e)
end

-- Better: named parameters
local function good(opts)
  opts = opts or {}
  local name = opts.name or "default"
  local timeout = opts.timeout or 1000
end
```

### Return Values
- Return early for guard clauses
- Use multiple return values sparingly

```lua
local function validate(input)
  if not input then
    return nil, "input required"
  end

  if type(input) ~= "string" then
    return nil, "input must be string"
  end

  return input
end
```

## Comments

### When to Comment
- Explain **why**, not **what**
- Document non-obvious behavior
- Reference issues/PRs for workarounds

```lua
-- Correct: explains why
-- Using pcall because plugin may not be installed
local ok, telescope = pcall(require, "telescope")

-- Incorrect: restates the code
-- Get the current buffer number
local bufnr = vim.api.nvim_get_current_buf()
```

### Documentation Comments
```lua
--- Calculate the sum of two numbers.
--- @param a number The first number
--- @param b number The second number
--- @return number The sum of a and b
local function add(a, b)
  return a + b
end
```

## Error Handling

### Use pcall for External Code
```lua
local ok, result = pcall(require, "external-module")
if not ok then
  vim.notify("Module not found", vim.log.levels.WARN)
  return
end
```

### Assert for Internal Errors
```lua
local function process(data)
  assert(data, "data is required")
  assert(type(data) == "table", "data must be a table")
  -- process...
end
```

### Graceful Degradation
```lua
local function feature()
  local ok, module = pcall(require, "optional-module")
  if ok then
    return module.enhanced_feature()
  else
    return fallback_implementation()
  end
end
```

## Tables

### Table Formatting
```lua
-- Short tables on one line
local point = { x = 10, y = 20 }

-- Longer tables with trailing comma
local config = {
  name = "example",
  enabled = true,
  options = {
    timeout = 1000,
    retries = 3,
  },
}
```

### Array Formatting
```lua
-- Short arrays
local list = { "a", "b", "c" }

-- Longer arrays
local events = {
  "BufReadPre",
  "BufNewFile",
  "FileType",
}
```
