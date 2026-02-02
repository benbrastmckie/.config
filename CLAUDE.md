# Neovim Configuration Guidelines

## Commands
[Used by: /test, /test-all]

- **Linting**: `vim.keymap.set("n", "<leader>l", function() lint.try_lint() end)`
- **Formatting**: `vim.keymap.set({"n", "v"}, "<leader>mp", function() conform.format(...) end)`
- **Testing**: `:TestNearest`, `:TestFile`, `:TestSuite`, `:TestLast`

## Code Standards
[Used by: /implement, /refactor, /plan]

### Lua Code Style
- **Indentation**: 2 spaces, expandtab
- **Line length**: ~100 characters
- **Imports**: At the top of the file, ordered by dependency
- **Module structure**: Organized in `neotex.core` and `neotex.plugins` namespaces
- **Plugin definitions**: Table-based with lazy.nvim format
- **Function style**: Use local functions where possible
- **Keymaps**: Document in comments, use `vim.keymap.set` with descriptive options
- **Error handling**: Use pcall for operations that might fail
- **Naming**: Use descriptive, lowercase names with underscores for variables/functions

## Project Organization
- Core functionality in `lua/neotex/core/`
- Plugin configurations in `lua/neotex/plugins/`
- LSP settings in dedicated `lua/neotex/plugins/lsp/` directory
- Filetype-specific settings in `after/ftplugin/`
- Deprecated features moved to `lua/neotex/deprecated/`

## Documentation Policy
[Used by: /document, /plan]

Each subdirectory in the nvim configuration MUST contain a README.md file that includes:

### Content Requirements
- **Purpose**: Clear explanation of the directory's role and functionality
- **Module Documentation**: Detailed documentation for each module/file in the directory
- **File Descriptions**: Brief but explanatory description of what each file does
- **Usage Examples**: Code examples or usage patterns where applicable
- **Navigation Links**: Links to README.md files in subdirectories (if any)
- **Parent Link**: Link to parent directory's README.md (if not root)

### Structure Template
```markdown
# Directory Name

Brief description of directory purpose.

## Modules

### filename.lua
Description of what this module does and its key functions.

## Subdirectories

- [subdirectory-name/](subdirectory-name/README.md) - Brief description

## Navigation
- [← Parent Directory](../README.md)
```

### Style Guidelines
- Use clear, concise language
- Include code examples with syntax highlighting
- Maintain consistent formatting across all README files
- Link to relevant keymaps and commands where applicable
- Document any dependencies or requirements

## ASCII Diagrams and Box Drawing

When creating diagrams in documentation, use Unicode box-drawing characters for professional-looking diagrams that render well in modern editors.

### Recommended Unicode Box Drawing Characters
These UTF-8 characters create clean, professional diagrams (as used in ARCHITECTURE_V3.md):

#### Corners
- `┌` (U+250C) - Top left corner
- `┐` (U+2510) - Top right corner  
- `└` (U+2514) - Bottom left corner
- `┘` (U+2518) - Bottom right corner

#### Lines
- `─` (U+2500) - Horizontal line
- `│` (U+2502) - Vertical line

#### Intersections
- `├` (U+251C) - Vertical line with right branch
- `┤` (U+2524) - Vertical line with left branch
- `┬` (U+252C) - Horizontal line with down branch
- `┴` (U+2534) - Horizontal line with up branch
- `┼` (U+253C) - Four-way intersection

### Example Professional Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                    Component Name                           │
│              Description of component                       │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────────┐
│                    Another Component                        │
│              Can access the component above                 │
└─────────────────────────────────────────────────────────────┘
```

### How to Type These Characters
1. **Copy from this guide**: Copy the characters directly from above
2. **Unicode input**: 
   - Linux: Ctrl+Shift+U, then type the hex code (e.g., 250C for ┌)
   - Mac: Use Character Viewer or Unicode Hex Input
   - Windows: Alt+X after typing the hex code
3. **Editor plugins**: Many editors have box-drawing plugins
4. **Copy from existing files**: ARCHITECTURE_V3.md has examples

### Best Practices
1. **Use Consistently**: Use the same style throughout a document
2. **UTF-8 Encoding**: Ensure your file is saved with UTF-8 encoding
3. **Test Display**: Verify the diagram displays correctly in GitHub/GitLab
4. **Align Carefully**: Use monospace fonts and align characters precisely
5. **Modern Editors**: These characters work well in Neovim, VS Code, etc.

## Character Encoding and Emoji Policy

### NO EMOJIS IN FILE CONTENT
**NEVER use emojis in file content** - they can cause bad characters and encoding issues when saved to disk.

**Exception**: Emojis are allowed in runtime UI elements (pickers, notifications, etc.) where they are displayed but not saved to files.

#### Forbidden Characters (in files)
- [✗] Emojis (target, checkmarks, crosses, clipboards, etc.) - cause bad character encoding
- [✗] Unicode symbols beyond basic box-drawing (lightbulbs, tools, rockets, etc.)
- [✗] Any non-ASCII decorative characters that may not render properly

#### Approved Alternatives
Instead of emojis, use:
- `[✓]` or `[DONE]` instead of checkmark emojis
- `[✗]` or `[FAIL]` instead of cross emojis  
- `[!]` or `[WARN]` instead of warning emojis
- `[i]` or `[INFO]` instead of info emojis
- `**` for emphasis instead of decorative symbols
- Plain text descriptions instead of pictographs

#### Safe Characters
- Basic ASCII (a-z, A-Z, 0-9, punctuation)
- Standard markdown symbols (*, -, #, etc.)
- Unicode box-drawing characters (listed above)
- Basic mathematical symbols (+, -, =, <, >, etc.)

### Encoding Guidelines
1. **Always use UTF-8 encoding** for all files
2. **Test file display** in multiple contexts (terminal, editor, web)
3. **Avoid fancy Unicode** unless specifically needed and tested
4. **Prefer ASCII** when possible for maximum compatibility

## Testing Protocols
[Used by: /test, /test-all, /implement]

### Test Commands
- **Run nearest test**: `:TestNearest` - Test function/block under cursor
- **Test current file**: `:TestFile` - Run all tests in current file
- **Test suite**: `:TestSuite` - Run all tests in project
- **Repeat last test**: `:TestLast` - Re-run most recent test

### Test Patterns
- Test files: `*_spec.lua`, `test_*.lua`
- Test location: `tests/` directory or adjacent to source files
- Test framework: Busted, plenary.nvim, or project-specific

### Quality Standards
- All new Lua modules must have test coverage
- Public APIs require comprehensive tests
- Use `pcall` in tests for error condition testing
- Mock external dependencies appropriately

### Lua Testing Assertion Patterns

When testing string pattern matching with `string:match()`, use the correct assertion types:

#### Correct Patterns
- **Match success**: `assert.is_not_nil(str:match("pattern"))` - Tests if pattern found
- **Match failure**: `assert.is_nil(str:match("pattern"))` - Tests if pattern not found

#### Incorrect Patterns (DO NOT USE)
- `assert.is_true(str:match("pattern"))` - WRONG: match returns string/nil, not boolean
- `assert.is_false(str:match("pattern"))` - WRONG: match returns string/nil, not boolean

#### Rationale
Lua's `string:match()` returns:
- The matched substring (truthy string) if pattern found
- `nil` if pattern not found
- Never returns boolean `true` or `false`

Using `is_true`/`is_false` with `string:match()` causes test failures because:
- `assert.is_true("matched")` fails - expects boolean true, gets string
- `assert.is_false(nil)` fails - expects boolean false, gets nil

#### Code Examples

Correct:
```lua
local result = "test string"
assert.is_not_nil(result:match("test"))      -- Verifies match found
assert.is_nil(result:match("missing"))       -- Verifies match not found
```

Incorrect:
```lua
local result = "test string"
assert.is_true(result:match("test"))         -- FAILS: returns "test", not true
assert.is_false(result:match("missing"))     -- FAILS: returns nil, not false
```

Reference: See `scan_spec.lua:203-204` for established codebase pattern.

## Standards Discovery
[Used by: all commands]

This CLAUDE.md is the root configuration file for the Neovim configuration repository.

### Related Configuration
- `.claude/CLAUDE.md` - Task management and agent orchestration system
- This file contains Neovim-specific coding standards and guidelines
- Both files should be consulted for complete standards