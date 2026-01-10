---
paths: "**/*.lua"
---

# Neovim/Lua Development Rules

## Test-Driven Development

**MANDATORY**: All implementations follow TDD:

```
1. RED: Write failing test first
2. GREEN: Write minimal code to pass
3. REFACTOR: Improve while tests pass
```

### Test Commands

```bash
# Run all tests with plenary
nvim --headless -c "PlenaryBustedDirectory tests/"

# Run specific test file
nvim --headless -c "PlenaryBustedFile tests/path/to/test_spec.lua"

# Run tests with minimal init
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

# Check Lua syntax
luacheck lua/
```

## Lua Code Style

### Formatting

- **Indentation**: 2 spaces, expandtab (no tabs)
- **Line length**: ~100 characters soft limit, 120 hard limit
- **Whitespace**: One blank line between functions, no trailing whitespace
- **Trailing commas**: Use in multi-line table definitions

### Naming Conventions

```lua
-- Variables and functions: snake_case
local session_manager = require("neotex.core.session")
local is_valid = validate_input(data)

-- Boolean variables: is_, has_, should_ prefix
local is_enabled = config.enabled
local has_permissions = check_access(path)

-- Module tables: M (conventional)
local M = {}

-- Constants: SCREAMING_SNAKE_CASE
local DEFAULT_TIMEOUT = 5000
local MAX_RETRIES = 3

-- Private functions: underscore prefix
local function _validate_uuid(uuid)
  -- ...
end
```

### Module Structure

```lua
-- Brief module description
--
-- Longer explanation if needed.

local M = {}

-- Dependencies
local utils = require("neotex.util.utils")

-- Constants
local DEFAULT_CONFIG = {
  enabled = true,
  timeout = 5000,
}

-- Module State
M.config = {}


-- Section: Private Helpers

local function _validate_input(input)
  -- ...
end


-- Section: Public API

--- Setup module with user configuration
---@param opts table|nil Configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts or {})
end

return M
```

### Project Organization

```
lua/neotex/
├── init.lua              # Namespace initialization
├── bootstrap.lua         # Plugin manager setup
├── config/               # Core NeoVim configuration
│   ├── options.lua       # Vim options
│   ├── keymaps.lua       # Global keymaps
│   └── autocmds.lua      # Autocommands
├── plugins/              # Plugin configurations
│   ├── ai/               # AI tools (Claude, Goose)
│   ├── editor/           # Editor enhancements
│   ├── lsp/              # Language servers
│   ├── text/             # Text editing (LaTeX, Markdown)
│   ├── tools/            # Development tools
│   └── ui/               # UI enhancements
├── core/                 # Core functionality
└── util/                 # Utility functions
```

## lazy.nvim Plugin Patterns

### Standard Plugin Spec

```lua
-- lua/neotex/plugins/category/plugin-name.lua
return {
  "author/plugin-name",
  event = "VeryLazy",  -- or: BufReadPre, InsertEnter, etc.
  dependencies = {
    "required/dependency",
  },
  opts = {
    -- Plugin configuration
  },
  config = function(_, opts)
    require("plugin-name").setup(opts)
  end,
}
```

### Lazy Loading Triggers

```lua
-- Event-based (most common)
event = "VeryLazy"           -- After UI loads
event = "BufReadPre"         -- Before reading buffer
event = {"BufReadPost", "BufNewFile"}  -- Multiple events

-- Filetype-based
ft = {"lua", "vim"}          -- Specific filetypes

-- Command-based
cmd = {"PluginCommand", "OtherCommand"}

-- Key-based
keys = {
  { "<leader>x", "<cmd>PluginCommand<cr>", desc = "Execute plugin" },
}
```

### Centralized Keymap Strategy

- **Non-leader keymaps**: Define in `neotex/config/keymaps.lua`
- **Leader keymaps**: Define in `neotex/plugins/editor/which-key.lua`
- **Plugin keys table**: Keep empty (`keys = {}`) to prevent conflicts

## Testing Patterns

### Framework

- **Busted**: Primary Lua testing framework
- **plenary.nvim**: Neovim-specific testing utilities

### Test File Organization

- Test files: `*_spec.lua` or `test_*.lua`
- Test location: `tests/` directory
- Fixtures: `tests/fixtures/`

### Assertion Patterns

```lua
-- CORRECT: Use is_nil/is_not_nil for string:match()
local result = "test string"
assert.is_not_nil(result:match("test"))    -- Match found
assert.is_nil(result:match("missing"))     -- Match not found

-- WRONG: match() returns string/nil, not boolean
-- assert.is_true(result:match("test"))    -- FAILS
-- assert.is_false(result:match("missing")) -- FAILS
```

### Test Structure

```lua
describe("module_name", function()
  local module

  before_each(function()
    module = require("neotex.module")
  end)

  describe("function_name", function()
    it("should handle basic case", function()
      local result = module.function_name("input")
      assert.equals("expected", result)
    end)

    it("should return nil for invalid input", function()
      local result = module.function_name(nil)
      assert.is_nil(result)
    end)
  end)
end)
```

## Error Handling

### Protected Calls (pcall)

```lua
-- Isolate plugin failures
local ok, plugin = pcall(require, "external.plugin")
if not ok then
  vim.notify("Plugin not available", vim.log.levels.WARN)
  return
end

-- Fallback behavior
local function get_git_root()
  local ok, result = pcall(vim.fn.systemlist, "git rev-parse --show-toplevel")
  if ok and vim.v.shell_error == 0 then
    return result[1]
  end
  return vim.fn.getcwd()  -- Fallback
end
```

### Error Propagation

```lua
--- Load session by ID
---@param session_id string Session UUID
---@return table|nil Session data or nil on error
---@return string|nil Error message if failed
function M.load_session(session_id)
  if not _is_valid_uuid(session_id) then
    return nil, "Invalid session UUID format"
  end

  local session_file = SESSION_DIR .. "/" .. session_id .. ".json"
  if vim.fn.filereadable(session_file) ~= 1 then
    return nil, "Session file not found"
  end

  return vim.json.decode(vim.fn.readfile(session_file))
end
```

### Early Returns

```lua
-- Good: Flat structure with early returns
function M.process(data, opts)
  if not data then
    return nil, "Data required"
  end

  if not opts or not opts.mode then
    return nil, "Mode option required"
  end

  local result = transform(data)
  return result
end
```

## NeoVim API Patterns

### API Preference

```lua
-- Prefer vim.api for buffer/window operations
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
vim.api.nvim_win_set_cursor(winnr, {row, col})

-- Use vim.fn when no API equivalent
local exists = vim.fn.filereadable(path) == 1

-- Avoid vim.cmd when API available
vim.cmd.edit(file)  -- OK
vim.api.nvim_cmd({cmd = "edit", args = {file}}, {})  -- Better
```

### Keymapping

```lua
-- Single mode
vim.keymap.set("n", "<leader>fs", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })

-- Multiple modes
vim.keymap.set({"n", "v"}, "<leader>y", '"+y', { desc = "Yank to clipboard" })

-- Buffer-local
vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover docs" })
```

### Options and Variables

```lua
-- Options
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2

-- Global variables
vim.g.mapleader = " "

-- Buffer-local
vim.b.some_config = { enabled = true }
```

### Autocommands

```lua
local augroup = vim.api.nvim_create_augroup("NeotexGroup", { clear = true })

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = augroup,
  callback = function()
    require("neotex.core.session").save_current()
  end,
  desc = "Save session before exit",
})

vim.api.nvim_create_autocmd({"BufReadPost", "BufNewFile"}, {
  group = augroup,
  pattern = "*.tex",
  callback = function()
    require("neotex.plugins.text.vimtex").setup_buffer()
  end,
  desc = "Setup VimTeX for LaTeX",
})
```

## Documentation Standards

### LuaLS Annotations

```lua
--- Main function description
---@param param1 string Description
---@param param2 table|nil Optional description
---@return boolean Success status
---@return string|nil Error message if failed
function M.main_function(param1, param2)
  -- Implementation
end

---@class Config
---@field enabled boolean Enable the feature
---@field timeout number|nil Timeout in milliseconds
```

### README Requirements

Every directory must contain README.md with:
- Purpose explanation
- Module documentation
- Usage examples
- Navigation links

### Character Encoding

- **UTF-8 encoding** for all files
- **NO EMOJIS in file content** (causes encoding issues)
- Use Unicode box-drawing for diagrams (see nvim/CLAUDE.md)
- Plain text alternatives: `[DONE]`, `[FAIL]`, `[WARN]`, `[INFO]`

## Code Quality

### Function Size

- Keep functions focused and small (<50 lines preferred)
- One level of abstraction per function
- Extract complex logic into helpers

### Table Patterns

```lua
-- Table merging
M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_opts)

-- Table construction with trailing commas
local config = {
  mode = "development",
  timeout = 5000,
  features = {
    auto_save = true,
  },
}
```

### Performance

- Use lazy loading for plugins
- Cache module requires and expensive computations
- Avoid repeated work in hot paths
- Target <150ms startup (check with `:StartupTime`)

## Common Commands

```vim
" Check startup time
:StartupTime

" Find keymap conflicts
:verbose map <key>

" Check loaded modules
:lua print(vim.inspect(package.loaded))

" Check for errors
:messages

" Reload module during development
:lua package.loaded['module.name'] = nil
:lua require('module.name')
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Slow startup | Use lazy loading, defer plugins |
| Keymap conflicts | Check `:verbose map <key>` |
| Module not found | Verify require path matches file structure |
| Plugin errors | Check dependencies in spec |
