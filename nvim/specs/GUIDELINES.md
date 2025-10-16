# Neovim Configuration Development Guidelines

This document provides comprehensive guidelines for development in the Neovim configuration. These principles ensure clean, maintainable, and efficient code while respecting the realities of a working Neovim setup.

## Core Philosophy

### Evolution, Not Revolution
**IMPORTANT**: While we strive for architectural purity, this codebase acknowledges pragmatic compromises necessary for a functional Neovim configuration. Document these compromises clearly and work toward better patterns over time.

### Systematic Analysis Before Implementation
Before implementing any changes, conduct a thorough analysis to understand:
1. How new changes will integrate with existing code
2. What redundancies can be eliminated without breaking functionality
3. How to improve simplicity and maintainability
4. What existing patterns and working code can be preserved
5. Where pragmatic compromises are acceptable

The goal is to enhance the unity, elegance, and integrity of the codebase through thoughtful evolution.

## Design Principles

### Core Principles
1. **Single Source of Truth**: One authoritative module for each domain
   - `neotex/config/keymaps.lua` for all non-leader keymaps
   - `neotex/plugins/editor/which-key.lua` for all leader keymaps
   - `neotex/core/` for core functionality
2. **Pragmatic Architecture**: Accept necessary compromises
3. **Incremental Improvement**: Evolve the codebase gradually while maintaining functionality
4. **Systematic Integration**: New code must work with existing patterns
5. **Living Documentation**: Keep documentation accurate to implementation reality
6. **Lazy Loading**: Use lazy.nvim effectively to minimize startup time

### Code Quality Goals
Every change should improve:
- **Simplicity**: Reduce complexity where possible without losing functionality
- **Unity**: Ensure components work together harmoniously
- **Maintainability**: Balance ideal patterns with practical needs
- **Reliability**: Preserve all working functionality through migrations
- **Performance**: Optimize startup time and runtime performance

## Code Style Standards

### Lua Style Guide

#### Basic Formatting
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters (soft limit)
- **File length**: Target 200-350 lines, maximum 400 lines
- **Naming**:
  - Use `snake_case` for variables and functions
  - Use `PascalCase` for module tables (e.g., `M`)
  - Use descriptive names (prefer `buffer_utils` over `bu`)

#### Code Structure
```lua
-- Module header comment
-- Brief description of module purpose

local M = {}

-- Dependencies at top, grouped logically
local core_module = require("neotex.core.module")
local util = require("neotex.util")

-- Local variables
local state = {}
local config = {}

-- Local helper functions
local function helper_function()
  -- Implementation
end

-- Public API functions
function M.public_function()
  -- Implementation
end

-- Setup/initialization
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
```

#### Error Handling Pattern
```lua
-- Use pcall for operations that might fail
local ok, result = pcall(risky_operation)
if not ok then
  vim.notify("Operation failed: " .. tostring(result), vim.log.levels.ERROR)
  return nil, result
end

-- For required modules
local ok, module = pcall(require, "module.name")
if not ok then
  return  -- Fail silently for optional features
end
```

### Plugin Configuration Standards

#### Lazy.nvim Plugin Structure
```lua
return {
  "author/plugin-name",
  event = "VeryLazy",  -- Or specific events
  dependencies = {
    "required/dependency",
  },

  -- Keep keys empty if defined in keymaps.lua
  keys = {},

  opts = {
    -- Configuration options
  },

  config = function(_, opts)
    require("plugin").setup(opts)
    -- Additional setup
  end,
}
```

#### Keymap Management
- **Non-leader keymaps**: Define in `neotex/config/keymaps.lua`
- **Leader keymaps**: Define in `neotex/plugins/editor/which-key.lua`
- **Plugin keys table**: Keep empty (`keys = {}`) to prevent conflicts
- **Buffer-local keymaps**: Use dedicated functions like `set_terminal_keymaps()`

Example keymap definition:
```lua
-- In keymaps.lua
map("n", "<C-p>", "<cmd>Telescope find_files<CR>", {}, "Find files")

-- For buffer-specific mappings
function _G.set_markdown_keymaps()
  buf_map(0, "n", "<C-n>", "<cmd>AutolistToggleCheckbox<CR>", "Toggle checkbox")
end
```

### Module Organization

#### Directory Structure
```
lua/neotex/
├── core/           # Core functionality (state, sessions, etc.)
├── config/         # Configuration files (keymaps, options, autocmds)
├── plugins/        # Plugin configurations organized by category
│   ├── ai/        # AI-related plugins
│   ├── editor/    # Editor enhancements
│   ├── lsp/       # Language server configurations
│   ├── tools/     # Development tools
│   └── ui/        # UI enhancements
├── util/          # Utility modules
└── deprecated/    # Deprecated code (temporary, for migration)
```

#### Module Namespace
- Use consistent namespace: `neotex.category.module`
- Examples:
  - `neotex.core.state`
  - `neotex.plugins.ai.claudecode`
  - `neotex.util.buffer`

## Development Process

### Pre-Implementation Analysis

Before writing any code:

1. **Analyze Existing Codebase**
   ```markdown
   - What modules will be affected?
   - What can be deleted or simplified?
   - What redundancies exist?
   - How will new code integrate?
   ```

2. **Design for Simplicity**
   ```markdown
   - Can existing modules be reused?
   - What is the minimal implementation?
   - How can we reduce total lines of code?
   - What abstractions can be eliminated?
   ```

3. **Plan Integration**
   ```markdown
   - How will changes affect other modules?
   - What APIs need updating?
   - What documentation needs updates?
   - Will startup time be affected?
   ```

### Implementation Guidelines

#### Adding New Features
1. Check if similar functionality exists
2. Reuse existing utilities and patterns
3. Follow established module structure
4. Add appropriate error handling
5. Document public APIs

#### Refactoring Existing Code
1. Preserve backward compatibility during migration
2. Use deprecation warnings for breaking changes
3. Update all dependent code incrementally
4. Test thoroughly before removing old code

#### Performance Considerations
1. Use lazy loading where possible
2. Minimize synchronous operations during startup
3. Profile changes with `:StartupTime`
4. Avoid unnecessary global functions

## Testing and Validation

### Manual Testing Checklist
- [ ] Basic functionality works as expected
- [ ] No errors on startup (`:messages`)
- [ ] Keybindings work correctly
- [ ] Plugin integrations function properly
- [ ] Performance is acceptable (`:StartupTime` < 150ms ideal)

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Slow startup | Use lazy loading, defer non-essential plugins |
| Keymap conflicts | Check `:verbose map <key>` and centralize in keymaps.lua |
| Module not found | Verify require paths match file structure |
| Plugin errors | Check dependencies and load order |

## Documentation Standards

### README.md Requirements

Every subdirectory MUST have a README.md that includes:

```markdown
# Module/Directory Name

Brief description of purpose and functionality.

## Modules

### module1.lua
Description of what this module does and its key functions.

### module2.lua
Description of what this module does and its key functions.

## API Reference
Document public functions and their usage.

## Dependencies
- Uses: `neotex.util.module`
- Used by: `neotex.plugins.example`

## Examples
```lua
-- Example usage
local module = require("neotex.category.module")
module.function()
```

## Navigation
- [← Parent Directory](../README.md)
- [→ Subdirectory](subdirectory/README.md)
```

### Inline Documentation
```lua
--- Module description
--- @module neotex.module.name

--- Function description
--- @param param1 string Description of parameter
--- @param param2 table Optional parameter
--- @return boolean success
--- @return string|nil error message
function M.documented_function(param1, param2)
  -- Implementation
end
```

## Character Encoding and Formatting

### NO EMOJIS IN FILE CONTENT
**NEVER use emojis in file content** - they can cause encoding issues.

**Exception**: Emojis are allowed in runtime UI elements (notifications, pickers) where they are displayed but not saved to files.

### Safe Characters
- Basic ASCII (a-z, A-Z, 0-9, punctuation)
- Standard markdown symbols (*, -, #, etc.)
- Unicode box-drawing characters for diagrams
- Basic mathematical symbols (+, -, =, <, >, etc.)

### Box Drawing for Diagrams
Use Unicode box-drawing characters for professional diagrams:
```
┌─────────────────────────────────────────┐
│            Component Name               │
│        Description of component         │
└─────────────────────────────────────────┘
```

Characters:
- Corners: `┌` `┐` `└` `┘`
- Lines: `─` `│`
- Intersections: `├` `┤` `┬` `┴` `┼`

## Pragmatic Compromises

### Acceptable Trade-offs
Document when you make pragmatic compromises:
```lua
-- NOTE: This module has UI dependencies for practical reasons
-- Future: Consider event-based system for better separation
```

### Common Patterns

#### Lazy Module Loading
```lua
-- Defer loading until needed
local module = nil
local function get_module()
  if not module then
    module = require("heavy.module")
  end
  return module
end
```

#### Optional Dependencies
```lua
-- Gracefully handle missing optional dependencies
local has_telescope, telescope = pcall(require, "telescope")
if has_telescope then
  -- Use telescope features
end
```

#### Configuration Merging
```lua
-- Standard pattern for option handling
local defaults = {
  option1 = true,
  option2 = "value",
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})
  -- Apply configuration
end
```

## Migration Strategy

### Clean Breaking Changes
When a better design/architecture is available, make changes cleanly and systematically rather than maintaining backward compatibility at the cost of code quality.

### Migration Process
1. **Comprehensive Analysis Phase**
   ```markdown
   - Map ALL usages of the old implementation
   - Identify every file that will be affected
   - Document all dependencies and integration points
   - Plan the complete migration path
   ```

2. **Design New Architecture**
   ```markdown
   - Design the new structure without legacy constraints
   - Focus on the best possible implementation
   - Document why the new design is superior
   - Ensure the new design solves root problems, not symptoms
   ```

3. **Execute Complete Migration**
   ```lua
   -- BAD: Maintaining old patterns for compatibility
   function M.old_function_name()  -- Keep for backward compat
     return M.new_better_function()
   end

   -- GOOD: Clean break with comprehensive update
   -- Update ALL call sites to use new_better_function directly
   -- Delete old_function_name entirely
   ```

4. **Systematic Update**
   - Update ALL references in a single, atomic change
   - Use search and replace tools effectively
   - Verify no orphaned references remain
   - Test every affected module

### When to Break Compatibility

Break from old implementations when:
- The new design is significantly cleaner
- Maintaining compatibility would pollute the codebase
- The old pattern encourages bad practices
- Technical debt would increase with compatibility layers

### Migration Checklist
- [ ] Documented all files affected by the change
- [ ] Searched entire codebase for all references
- [ ] Updated every reference to use new implementation
- [ ] Removed old implementation completely
- [ ] Tested all affected functionality
- [ ] Updated documentation to reflect new patterns
- [ ] No compatibility shims or deprecated wrappers remain

### Example: Clean Module Restructure
```lua
-- BEFORE: Scattered functionality
-- utils/init.lua (400 lines, mixed concerns)

-- AFTER: Clean separation
-- utils/string.lua (100 lines)
-- utils/table.lua (100 lines)
-- utils/buffer.lua (100 lines)

-- Migration approach:
-- 1. Map all require("utils") calls
-- 2. Create new focused modules
-- 3. Update ALL requires in one comprehensive pass
-- 4. Delete old utils/init.lua entirely
-- 5. No compatibility layer - clean break
```

### Documentation of Breaking Changes
When making breaking changes:
```markdown
## Migration: [Module Name] Restructure

### What Changed
- Old: `require("old.path")`
- New: `require("new.better.path")`

### Why Changed
- Cleaner architecture
- Better separation of concerns
- Reduced complexity

### Files Updated
- [x] config/keymaps.lua (lines 45, 89, 123)
- [x] plugins/tool.lua (line 67)
- [x] core/module.lua (lines 12, 34)

### Testing Performed
- [x] All keybindings work
- [x] No startup errors
- [x] Affected features tested manually
```

## Quality Checklist

Before committing changes:

- [ ] Code follows style guidelines
- [ ] No startup errors
- [ ] Keybindings work correctly
- [ ] Documentation updated
- [ ] README.md files updated/created
- [ ] Performance impact assessed
- [ ] Backward compatibility maintained (or documented breaking changes)
- [ ] Complex functions have comments
- [ ] Public APIs are documented

## Common Commands for Development

```vim
" Check startup time
:StartupTime

" Find keymap conflicts
:verbose map <key>

" Check loaded modules
:lua print(vim.inspect(package.loaded))

" Profile a function
:lua vim.cmd('profile start profile.log')
:lua vim.cmd('profile func *')
" ... perform action ...
:lua vim.cmd('profile stop')

" Check for errors
:messages

" Reload a module during development
:lua package.loaded['module.name'] = nil
:lua require('module.name')
```

## Summary

These guidelines balance architectural ideals with the practical needs of a working Neovim configuration. By acknowledging necessary compromises while working toward better patterns, we maintain a fast, reliable, and maintainable configuration.

Remember:
- **Evolution, not revolution** - Every change should preserve functionality while incrementally improving architecture
- **Document everything** - Especially compromises and non-obvious decisions
- **Centralize concerns** - Keep keymaps, options, and autocmds in their designated locations
- **Test thoroughly** - A broken config means no productivity