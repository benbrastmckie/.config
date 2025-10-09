# Code Standards

## Purpose

This document defines coding standards and conventions for all Lua code in the NeoVim configuration. These standards prioritize clean, maintainable code without historical baggage or compatibility layers.

## Core Principles

### Design Philosophy

**Single Source of Truth**:
- One authoritative module for each domain
- `neotex/config/keymaps.lua` for all non-leader keymaps
- `neotex/plugins/editor/which-key.lua` for all leader keymaps
- `neotex/core/` for core functionality

**Code Quality Goals**:
Every change should improve:
- **Simplicity**: Reduce complexity without losing functionality
- **Unity**: Ensure components work together harmoniously
- **Maintainability**: Code that is easy to understand and modify
- **Reliability**: Preserve working functionality through changes
- **Performance**: Optimize startup time and runtime efficiency

### Clean-Break Refactoring

Code quality and coherence take priority over backward compatibility.

**Principles**:
- Remove deprecated patterns entirely rather than maintaining compatibility layers
- Refactor for clarity and maintainability over preservation of legacy code
- Trust git history for historical context
- Delete commented-out code instead of preserving "just in case"

**When to Break Compatibility**:
- The new design is significantly cleaner
- Maintaining compatibility would pollute the codebase
- The old pattern encourages bad practices
- Technical debt would increase with compatibility layers

**Systematic Migration Process**:
1. **Map all usages** of the old implementation
2. **Design new architecture** without legacy constraints
3. **Update ALL references** in a single, atomic change
4. **Remove old implementation** completely
5. **Test thoroughly** to ensure functionality preserved
6. **Update documentation** to reflect only current patterns

### Present-State Code Comments

Code comments must describe current implementation only.

**Prohibited**:
- Historical notes: "Changed from X to Y", "TODO: migrate from old system"
- Version markers: "Added in v2.0", "Deprecated in v1.5"
- Compatibility notes: "Legacy support for old API"
- Migration comments: "Will replace X with Y later"

**Required**:
- WHY code does something (when not obvious)
- WHAT complex logic accomplishes
- IMPORTANT edge cases or constraints
- PUBLIC API documentation

**Good Comments**:
```lua
-- Check session validity before restore to prevent loading corrupted state
if not is_valid_session(session_id) then
  return nil, "Invalid session UUID format"
end

-- Use pcall to isolate plugin failures and prevent cascade errors
local ok, err = pcall(require, plugin_module)
```

**Bad Comments**:
```lua
-- Updated 2024-10-01: Changed to UUID-based sessions
-- TODO: Remove old timestamp-based session support after migration
-- Legacy compatibility: still supports old session format
-- Previously this used os.time() but that caused collisions
```

### No Dead Code

Delete rather than comment out or deprecate.

**Remove**:
- Commented-out functions or blocks
- Unused utility functions
- Deprecated API compatibility shims
- "TODO: delete this later" code

**Keep**:
- Temporarily commented debug statements during active development (remove before commit)
- Conditional debug code with clear purpose

## Lua Language Standards

### Formatting and Style

**Indentation**:
- 2 spaces per level
- Use `expandtab` (spaces, not tabs)
- Consistent indentation in chained method calls

**Line Length**:
- Soft limit: 100 characters
- Hard limit: 120 characters
- Break long function calls across multiple lines with aligned parameters

**Whitespace**:
- One blank line between top-level functions
- Two blank lines between major sections
- No trailing whitespace
- Blank line at end of file

**Example**:
```lua
local M = {}

-- Section: Core Functions

function M.process_item(item, options)
  local result = item.data
  if options.transform then
    result = options.transform(result)
  end
  return result
end


-- Section: Public API

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.defaults, opts)
end

return M
```

### Naming Conventions

**Variables and Functions**:
- `snake_case` for all variables and functions
- Descriptive names over abbreviations
- Boolean variables prefixed with `is_`, `has_`, `should_`

```lua
-- Good
local session_manager = require("neotex.core.session")
local is_valid = session_manager.validate_uuid(session_id)
local has_permissions = check_file_access(path)

-- Bad
local sm = require("neotex.core.session")
local valid = sm.validate(sid)
local perms = check(p)
```

**Module Tables**:
- `PascalCase` or `M` for module export tables
- `M` is conventional and preferred for consistency

```lua
local M = {}

M.config = {}
M.state = {}

function M.setup(opts)
  -- ...
end

return M
```

**Constants**:
- `SCREAMING_SNAKE_CASE` for true constants
- Place at top of module after requires

```lua
local M = {}

local DEFAULT_TIMEOUT = 5000
local MAX_RETRIES = 3
local SESSION_DIR = vim.fn.stdpath("data") .. "/sessions"
```

**Private Functions**:
- Prefix with underscore: `_private_function`
- Place private functions above public API
- Document if non-obvious

```lua
-- Private helper to validate UUID format
local function _is_valid_uuid(uuid)
  return uuid and uuid:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

-- Public API
function M.validate_session(session_id)
  if not _is_valid_uuid(session_id) then
    return false, "Invalid session UUID"
  end
  -- ...
end
```

### Module Structure

**Standard Module Pattern**:

```lua
-- Brief module description
--
-- Longer explanation if needed, describing purpose and main concepts.
-- No historical notes about why it was created or when it changed.

local M = {}

-- Dependencies
local utils = require("neotex.util.utils")
local logger = require("neotex.util.logger")

-- Constants
local DEFAULT_CONFIG = {
  enabled = true,
  timeout = 5000,
}

-- Module State (if needed)
M.config = {}
M._state = {}  -- Private state


-- Section: Private Helpers

local function _validate_input(input)
  -- ...
end

local function _process_data(data)
  -- ...
end


-- Section: Public API

--- Setup module with user configuration
---@param opts table|nil Configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts or {})
end

--- Main function description
---@param param1 string Description
---@param param2 table|nil Optional description
---@return boolean Success status
---@return string|nil Error message if failed
function M.main_function(param1, param2)
  -- Implementation
end


return M
```

**Module Organization**:
1. Module description comment
2. Module table declaration (`local M = {}`)
3. Dependencies (`require` statements)
4. Constants
5. Module state/config
6. Private helper functions
7. Public API functions
8. Return statement

### Error Handling

**Protected Calls**:
- Use `pcall` for operations that might fail
- Isolate plugin loads to prevent cascade failures
- Handle errors gracefully with fallbacks

```lua
-- Good: Isolate plugin failures
local ok, plugin = pcall(require, "external.plugin")
if not ok then
  vim.notify("Plugin 'external.plugin' not available, feature disabled", vim.log.levels.WARN)
  return
end

-- Good: Provide fallback behavior
local function get_git_root()
  local ok, result = pcall(vim.fn.systemlist, "git rev-parse --show-toplevel")
  if ok and vim.v.shell_error == 0 then
    return result[1]
  end
  return vim.fn.getcwd()  -- Fallback to current directory
end
```

**Error Propagation**:
- Return `nil, error_message` for recoverable errors
- Throw errors for programming mistakes or unrecoverable failures
- Document error conditions in function comments

```lua
--- Load session by ID
---@param session_id string Session UUID
---@return table|nil Session data or nil on error
---@return string|nil Error message if failed
function M.load_session(session_id)
  -- Recoverable: return nil + error
  if not _is_valid_uuid(session_id) then
    return nil, "Invalid session UUID format"
  end

  local session_file = SESSION_DIR .. "/" .. session_id .. ".json"
  if not vim.fn.filereadable(session_file) then
    return nil, "Session file not found: " .. session_id
  end

  -- Unrecoverable: let error propagate
  local content = vim.fn.readfile(session_file)
  local session = vim.json.decode(table.concat(content, "\n"))

  return session
end
```

**Validation**:
- Validate inputs at function boundaries
- Fail fast with clear error messages
- Use assertions for internal invariants

```lua
function M.configure(opts)
  -- Validate type
  if opts ~= nil and type(opts) ~= "table" then
    error("configure() expects table or nil, got " .. type(opts))
  end

  -- Validate required fields
  if opts.session_dir and type(opts.session_dir) ~= "string" then
    error("opts.session_dir must be a string")
  end

  -- Internal invariant
  assert(M._initialized, "Module must be initialized before configure()")
end
```

### Table and Data Structures

**Table Construction**:
- Use table literals where possible
- Prefer explicit over computed keys for readability
- Trailing commas in multi-line table definitions

```lua
-- Good
local config = {
  mode = "development",
  timeout = 5000,
  features = {
    auto_save = true,
    notifications = true,
  },
}

-- Also good: Single line for short tables
local point = { x = 10, y = 20 }
```

**Table Merging**:
- Use `vim.tbl_deep_extend` for deep merging
- Use `vim.tbl_extend` for shallow merging
- Document merge strategy ("force", "keep", "error")

```lua
-- Deep merge: user config overrides defaults
M.config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_opts)

-- Shallow merge: keep existing values
local state = vim.tbl_extend("keep", current_state, initial_state)
```

**Table Iteration**:
- Use `pairs()` for dictionary tables
- Use `ipairs()` for array tables
- Cache `#table` if used in loop condition

```lua
-- Dictionary iteration
for key, value in pairs(config_table) do
  process(key, value)
end

-- Array iteration
for i, item in ipairs(list) do
  process(item)
end

-- Cached length for performance
local items_count = #items
for i = 1, items_count do
  process(items[i])
end
```

### Function Design

**Function Signatures**:
- Required parameters first, optional parameters last
- Use `nil` for optional parameters (not false)
- Default optional params at function start

```lua
function M.create_session(name, opts)
  opts = opts or {}
  local timeout = opts.timeout or DEFAULT_TIMEOUT
  local persist = opts.persist ~= false  -- Default true

  -- ...
end
```

**Return Values**:
- Single return value for simple success
- Multiple returns for success + data or nil + error
- Boolean first for success/failure, data second

```lua
-- Simple success
function M.save()
  -- ...
  return true
end

-- Success with data
function M.load()
  -- ...
  return session_data
end

-- Success/failure with data or error
function M.fetch(id)
  if not valid(id) then
    return nil, "Invalid ID"
  end

  local data = get_data(id)
  if not data then
    return nil, "Data not found"
  end

  return data
end
```

**Function Size**:
- Keep functions focused and small (prefer <50 lines)
- Extract complex logic into helper functions
- One level of abstraction per function

```lua
-- Good: Single responsibility, clear purpose
function M.restore_session(session_id)
  local session, err = _load_session_data(session_id)
  if not session then
    return false, err
  end

  _restore_buffers(session.buffers)
  _restore_windows(session.windows)
  _restore_state(session.state)

  return true
end

-- Bad: Multiple responsibilities, too much detail
function M.restore_session(session_id)
  local file = SESSION_DIR .. "/" .. session_id .. ".json"
  local content = vim.fn.readfile(file)
  local data = vim.json.decode(table.concat(content, "\n"))

  for _, buf in ipairs(data.buffers) do
    vim.cmd("edit " .. buf.name)
    vim.api.nvim_buf_set_lines(buf.id, 0, -1, false, buf.lines)
    -- ... 20 more lines of buffer restoration
  end

  -- ... 30 more lines of window and state restoration
end
```

### Lua Idioms and Best Practices

**Existence Checks**:
- Use truthiness but be aware of false vs nil
- Explicit nil checks when false is valid value

```lua
-- Simple existence check (nil or false are both falsy)
if config.enabled then
  do_something()
end

-- Explicit nil check (false is different from nil)
if config.enabled ~= nil then
  do_something(config.enabled)
end

-- Check table key existence
if config.feature ~= nil then
  use_feature(config.feature)
end
```

**String Operations**:
- Use string methods via `:` syntax
- Prefer `string.format` for complex formatting
- Use `vim.fn.expand` for path expansion

```lua
-- String methods
local upper = str:upper()
local trimmed = str:gsub("^%s+", ""):gsub("%s+$", "")

-- Formatting
local message = string.format("Session %s loaded with %d buffers", session_id, #buffers)

-- Path handling
local config_dir = vim.fn.expand("~/.config/nvim")
local data_dir = vim.fn.stdpath("data")
```

**Conditional Assignment**:
- Use `or` for default values (careful with false)
- Use ternary-style for simple conditions

```lua
-- Default values (watch out: false or X returns X)
local timeout = opts.timeout or DEFAULT_TIMEOUT
local count = #items > 0 and #items or 1

-- Better for boolean: explicit check
local enabled = opts.enabled ~= nil and opts.enabled or true
```

**Early Returns**:
- Validate and return early to reduce nesting
- Handle error cases first

```lua
-- Good: Early returns, flat structure
function M.process(data, opts)
  if not data then
    return nil, "Data required"
  end

  if not opts or not opts.mode then
    return nil, "Mode option required"
  end

  local result = transform(data)
  save_result(result)
  return result
end

-- Bad: Nested conditions
function M.process(data, opts)
  if data then
    if opts and opts.mode then
      local result = transform(data)
      save_result(result)
      return result
    else
      return nil, "Mode option required"
    end
  else
    return nil, "Data required"
  end
end
```

## Development Process

### Pre-Implementation Analysis

Before implementing any changes:

1. **Analyze Existing Codebase**
   - What modules will be affected?
   - What can be deleted or simplified?
   - What redundancies exist?
   - How will new code integrate with existing patterns?

2. **Design for Simplicity**
   - Can existing modules be reused?
   - What is the minimal implementation?
   - How can we reduce total lines of code?
   - What abstractions can be eliminated?

3. **Plan Integration**
   - How will changes affect other modules?
   - What APIs need updating?
   - What documentation needs updates?
   - Will startup time be affected?

### Implementation Guidelines

**Adding New Features**:
1. Check if similar functionality exists
2. Reuse existing utilities and patterns
3. Follow established module structure
4. Add appropriate error handling
5. Document public APIs
6. Target 200-350 lines per file (maximum 400 lines)

**Refactoring Existing Code**:
1. Map ALL usages before changing anything
2. Design the new structure without legacy constraints
3. Update ALL dependent code in single atomic change
4. Test thoroughly before removing old code
5. Remove old implementation completely (no compatibility shims)

**Performance Considerations**:
1. Use lazy loading where possible
2. Minimize synchronous operations during startup
3. Profile changes with `:StartupTime` (target <150ms)
4. Avoid unnecessary global functions
5. Cache module requires and expensive computations

### Keymap Management Strategy

**Centralized Keymapping**:
- **Non-leader keymaps**: Define in `neotex/config/keymaps.lua`
- **Leader keymaps**: Define in `neotex/plugins/editor/which-key.lua`
- **Plugin keys table**: Keep empty (`keys = {}`) to prevent conflicts
- **Buffer-local keymaps**: Use dedicated functions (e.g., `set_terminal_keymaps()`)

**Example**:
```lua
-- In neotex/config/keymaps.lua (non-leader)
map("n", "<C-p>", "<cmd>Telescope find_files<CR>", {}, "Find files")

-- In neotex/plugins/editor/which-key.lua (leader keys)
["<leader>ff"] = { "<cmd>Telescope find_files<CR>", "Find files" }

-- Buffer-specific mappings
function _G.set_markdown_keymaps()
  buf_map(0, "n", "<C-n>", "<cmd>AutolistToggleCheckbox<CR>", "Toggle checkbox")
end
```

### Common Development Commands

```vim
" Check startup time
:StartupTime

" Find keymap conflicts
:verbose map <key>

" Check loaded modules
:lua print(vim.inspect(package.loaded))

" Check for errors
:messages

" Reload a module during development
:lua package.loaded['module.name'] = nil
:lua require('module.name')
```

## NeoVim-Specific Patterns

### API Usage

**Prefer vim.api over vim.fn**:
- Use `vim.api.*` for buffer/window/tab operations
- Use `vim.fn.*` only when no API equivalent exists
- Use `vim.cmd()` sparingly, prefer API when available

```lua
-- Good: vim.api for buffer operations
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
vim.api.nvim_win_set_cursor(winnr, {row, col})
vim.api.nvim_set_current_dir(path)

-- Acceptable: vim.fn when no API equivalent
local exists = vim.fn.filereadable(path) == 1
local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

-- Avoid: vim.cmd when API available
-- Bad
vim.cmd("edit " .. file)
-- Good
vim.cmd.edit(file)
-- Better
vim.api.nvim_cmd({cmd = "edit", args = {file}}, {})
```

**Keymapping**:
- Use `vim.keymap.set()` for all keymaps
- Specify mode explicitly
- Use descriptive descriptions for which-key integration

```lua
-- Good
vim.keymap.set("n", "<leader>fs", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })

-- Multiple modes
vim.keymap.set({"n", "v"}, "<leader>y", '"+y', { desc = "Yank to system clipboard" })

-- Buffer-local mapping
vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Show hover documentation" })
```

**Options**:
- Use `vim.opt` for option setting
- Use `vim.g` for global variables
- Use `vim.b` for buffer-local variables

```lua
-- Options
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2

-- Global variables
vim.g.mapleader = " "
vim.g.netrw_banner = 0

-- Buffer-local
vim.b.some_plugin_config = { enabled = true }
```

### Autocommands

**Use vim.api.nvim_create_autocmd**:
- Create augroups for organization
- Use descriptive group names
- Clear group before adding commands

```lua
-- Create augroup
local augroup = vim.api.nvim_create_augroup("NeotexSessions", { clear = true })

-- Add autocommands to group
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
  desc = "Setup VimTeX for LaTeX files",
})
```

### Plugin Configuration

**Lazy Loading**:
- Use lazy.nvim events and conditions
- Load on relevant events (VeryLazy, BufReadPre, etc.)
- Specify file types for filetype-specific plugins

```lua
{
  "plugin/name",
  event = "VeryLazy",  -- Most plugins
  ft = {"lua", "vim"},  -- Filetype-specific
  cmd = {"PluginCommand"},  -- Command-triggered
  keys = {  -- Keybinding-triggered
    { "<leader>x", "<cmd>PluginCommand<cr>", desc = "Execute plugin" },
  },
}
```

**Plugin Setup Pattern**:
```lua
-- In lua/neotex/plugins/category/plugin_name.lua
return {
  "author/plugin-name",
  event = "VeryLazy",
  dependencies = {
    "required/dependency",
  },
  opts = {
    -- Plugin options
  },
  config = function(_, opts)
    require("plugin-name").setup(opts)
  end,
}
```

### LSP Configuration

**Standard LSP Setup**:
```lua
local lspconfig = require("lspconfig")

-- Define capabilities from completion plugin
local capabilities = require("blink.cmp").get_lsp_capabilities()

-- Define on_attach for keymaps and settings
local on_attach = function(client, bufnr)
  -- Enable completion
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

  -- Keymaps
  local opts = { buffer = bufnr }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
end

-- Setup server
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
    },
  },
})
```

## Testing and Validation

### Manual Testing Checklist

Before committing changes:

- [ ] Basic functionality works as expected
- [ ] No errors on startup (check `:messages`)
- [ ] Keybindings work correctly (use `:verbose map <key>` for conflicts)
- [ ] Plugin integrations function properly
- [ ] Performance is acceptable (`:StartupTime` < 150ms ideal)
- [ ] Lazy loading works correctly
- [ ] Modified functionality tested manually
- [ ] All affected features verified

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Slow startup | Use lazy loading, defer non-essential plugins, profile with `:StartupTime` |
| Keymap conflicts | Check `:verbose map <key>` and centralize in keymaps.lua or which-key.lua |
| Module not found | Verify require paths match file structure under `lua/neotex/` |
| Plugin errors | Check dependencies in plugin spec, verify load order |
| Function not available | Ensure module is required before use, check for typos |

### Code Review Checklist

Quality checks before committing:

- [ ] Code follows style guidelines (2-space indent, snake_case, etc.)
- [ ] No dead code or commented-out blocks
- [ ] No historical comments or temporal language
- [ ] Error handling with pcall where appropriate
- [ ] Functions are focused and small (<50 lines preferred)
- [ ] Naming follows conventions (descriptive, snake_case)
- [ ] Public functions have LuaLS doc comments
- [ ] Module structure follows standard pattern
- [ ] No deprecated patterns or compatibility shims
- [ ] README.md files updated/created for affected directories
- [ ] Documentation updated to reflect changes
- [ ] Performance impact assessed
- [ ] Complex logic has explanatory comments (WHY, not WHAT)

## File Organization

### Directory Structure Standards

```
lua/neotex/
├── init.lua              # Namespace initialization (minimal)
├── bootstrap.lua         # Plugin manager setup
├── config/               # Core NeoVim configuration
│   ├── init.lua          # Config orchestration
│   ├── options.lua       # Vim options
│   ├── keymaps.lua       # Global keymaps
│   ├── autocmds.lua      # Autocommands
│   └── notifications.lua # Notification system
├── plugins/              # Plugin configurations
│   ├── init.lua          # Plugin loading orchestration
│   ├── ai/               # AI development tools
│   ├── editor/           # Editor enhancements
│   ├── lsp/              # LSP and completion
│   ├── text/             # Text editing (LaTeX, Markdown)
│   ├── tools/            # Development tools
│   └── ui/               # UI enhancements
├── core/                 # Core functionality modules
│   ├── session.lua       # Session management
│   └── git-info.lua      # Git integration
└── util/                 # Utility functions
    ├── utils.lua         # General utilities
    └── logger.lua        # Logging utilities
```

### File Naming

- `snake_case.lua` for all Lua files
- Descriptive names over abbreviations
- Match module name to filename
- Group related functionality in directories

## Performance Considerations

### Lazy Evaluation

- Defer expensive operations until needed
- Use lazy loading for plugins
- Cache computed values when appropriate

```lua
-- Good: Lazy loading with memoization
local M = {}
local _cached_root = nil

function M.get_git_root()
  if _cached_root then
    return _cached_root
  end

  local ok, result = pcall(vim.fn.systemlist, "git rev-parse --show-toplevel")
  if ok and vim.v.shell_error == 0 then
    _cached_root = result[1]
    return _cached_root
  end

  return vim.fn.getcwd()
end
```

### Avoid Repeated Work

- Cache module requires
- Memoize expensive computations
- Use autocommands instead of polling

```lua
-- Bad: Repeated requires
vim.keymap.set("n", "<leader>f", function()
  require("telescope.builtin").find_files()
end)

vim.keymap.set("n", "<leader>g", function()
  require("telescope.builtin").live_grep()
end)

-- Good: Cached require
local telescope_builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>f", telescope_builtin.find_files)
vim.keymap.set("n", "<leader>g", telescope_builtin.live_grep)
```

## Documentation in Code

### Module Documentation

Every module should have:
- Brief description at the top
- Explanation of purpose and main concepts
- No historical context

```lua
-- Session management with UUID-based session IDs
--
-- Provides session creation, persistence, and restoration with automatic
-- cleanup of stale sessions. Sessions are identified by cryptographically
-- random UUIDs to ensure uniqueness and prevent collisions.
--
-- Main concepts:
-- - Session: Serialized NeoVim state (buffers, windows, tabs, variables)
-- - Session ID: UUID v4 identifier for session files
-- - Session Directory: Data directory storage for session JSON files

local M = {}
-- ...
```

### Function Documentation

Public API functions should have LuaLS annotations:

```lua
--- Load and restore a session by ID
---
--- Reads session data from disk, validates format, and restores NeoVim
--- state including buffers, windows, and variables.
---
---@param session_id string UUID of session to restore
---@param opts table|nil Optional configuration
---@param opts.force boolean|nil Force load even if validation fails
---@return boolean success True if session restored successfully
---@return string|nil error Error message if restoration failed
function M.restore_session(session_id, opts)
  -- ...
end
```

**LuaLS Annotation Types**:
- `@param name type description`
- `@return type description`
- `@field name type description` (for tables)
- `@class ClassName`
- `@type type`

### Inline Comments

Use sparingly, only when:
- Logic is complex and non-obvious
- Explaining WHY something is done (not WHAT)
- Documenting important edge cases or constraints

```lua
-- Good: Explains WHY
-- Must validate UUID before file operations to prevent directory traversal
if not _is_valid_uuid(session_id) then
  return nil, "Invalid session ID"
end

-- Good: Documents edge case
-- Empty string from git command indicates detached HEAD state
if git_branch == "" then
  git_branch = "DETACHED"
end

-- Bad: Explains obvious WHAT
-- Set the timeout value
local timeout = 5000
```

## Related Documentation

- [DOCUMENTATION_STANDARDS.md](DOCUMENTATION_STANDARDS.md) - Documentation conventions and structure

## Summary

These code standards define the complete development approach for the NeoVim configuration, emphasizing:

**Philosophy**:
- Clean-break refactoring over backward compatibility
- Single source of truth for each concern
- Code quality improvements with every change
- Present-state focus without historical baggage

**Process**:
- Analyze before implementing
- Design for simplicity and integration
- Test thoroughly and systematically
- Document clearly and accurately

**Quality**:
- Consistent formatting and naming
- Proper error handling and validation
- Performance-conscious implementation
- Comprehensive testing before commits

When refactoring or adding new code, prioritize clarity, maintainability, and adherence to these conventions. Delete deprecated code entirely, avoid compatibility shims, and write code as if the current implementation always existed.
