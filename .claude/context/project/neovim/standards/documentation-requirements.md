# Documentation Requirements

## README Files

### Directory README Requirement
Every subdirectory in the configuration MUST contain a README.md that includes:

1. **Purpose** - Clear explanation of directory's role
2. **Module Documentation** - Documentation for each module/file
3. **File Descriptions** - Brief explanation of what each file does
4. **Usage Examples** - Code examples where applicable
5. **Navigation Links** - Links to subdirectory READMEs
6. **Parent Link** - Link to parent directory's README

### README Template
```markdown
# Directory Name

Brief description of directory purpose.

## Modules

### filename.lua
Description of what this module does and its key functions.

## Subdirectories

- [subdirectory-name/](subdirectory-name/README.md) - Brief description

## Navigation
- [Parent Directory](../README.md)
```

## Function Documentation

### LuaDoc Comments
Use LuaDoc-style comments for public functions:

```lua
--- Brief description of the function.
---
--- Longer description if needed, explaining behavior,
--- edge cases, and any important notes.
---
--- @param name string The name parameter
--- @param opts? table Optional configuration table
--- @param opts.timeout? number Timeout in milliseconds
--- @param opts.retries? number Number of retry attempts
--- @return boolean success Whether the operation succeeded
--- @return string? error Error message if failed
local function do_something(name, opts)
  -- implementation
end
```

### Common Annotations
| Annotation | Usage |
|------------|-------|
| `@param name type` | Parameter documentation |
| `@param name? type` | Optional parameter |
| `@return type` | Return value |
| `@return type?` | Optional return value |
| `@field name type` | Table field |
| `@class Name` | Class/type definition |
| `@alias Name type` | Type alias |
| `@type type` | Variable type |
| `@deprecated` | Mark as deprecated |
| `@see reference` | Cross-reference |

### When to Document
- All public module functions
- Complex internal functions
- Non-obvious behavior
- Configuration options

### When NOT to Document
- Obvious one-liners
- Private helper functions with clear names
- Standard patterns (e.g., M.setup)

## Inline Comments

### Use Comments For
- **Why** something is done (not what)
- Workarounds with issue references
- Complex algorithms
- Non-obvious side effects

```lua
-- Using pcall because plugin might not be installed
local ok, module = pcall(require, "optional-plugin")

-- Workaround for neovim#12345
vim.schedule(function()
  -- delayed operation
end)
```

### Avoid Comments For
- Restating the code
- Obvious operations
- Commented-out code (delete it)

```lua
-- Bad: restates the code
-- Get current buffer number
local bufnr = vim.api.nvim_get_current_buf()

-- Good: no comment needed, code is clear
local bufnr = vim.api.nvim_get_current_buf()
```

## File Headers

### Plugin Spec Files
No header needed - the plugin name is self-documenting.

### Utility Modules
Brief header for non-obvious modules:

```lua
--- Utility functions for buffer management.
--- @module neotex.core.buffer
local M = {}
```

### Complex Modules
Extended header for complex modules:

```lua
--- Telescope picker for project navigation.
---
--- Provides fuzzy finding across projects with:
--- - MRU (most recently used) sorting
--- - Project-specific file filtering
--- - Custom actions for project management
---
--- @module neotex.plugins.editor.telescope.pickers.projects
local M = {}
```

## Character Encoding

### UTF-8 Standard
- All files MUST use UTF-8 encoding
- Verify display in multiple contexts (terminal, editor, web)

### Allowed Characters
- Basic ASCII (a-z, A-Z, 0-9, punctuation)
- Standard markdown symbols (*, -, #, etc.)
- Unicode box-drawing characters for diagrams

### Box-Drawing Characters
For diagrams, use these UTF-8 characters:
```
Corners: ┌ ┐ └ ┘
Lines:   ─ │
Joins:   ├ ┤ ┬ ┴ ┼
```

Example:
```
┌─────────────────────┐
│     Component       │
└──────────┬──────────┘
           │
┌──────────┴──────────┐
│    Subcomponent     │
└─────────────────────┘
```

### NO EMOJIS
**NEVER use emojis in file content** - they cause encoding issues.

Exception: Emojis are allowed in runtime UI elements (pickers, notifications) where they are displayed but not saved to files.

#### Forbidden
- Checkmark emojis
- Warning/info icons
- Decorative symbols

#### Alternatives
| Instead of | Use |
|------------|-----|
| Checkmark emoji | `[DONE]` or `[x]` |
| Cross emoji | `[FAIL]` or `[ ]` |
| Warning emoji | `[WARN]` or `[!]` |
| Info emoji | `[INFO]` or `[i]` |

## Changelog

### When to Document Changes
- Breaking changes
- New features
- Bug fixes affecting behavior

### Format
Use conventional commit style in git commits:
```
feat(module): add new feature
fix(module): fix specific bug
docs(module): update documentation
refactor(module): improve code structure
```
