# Tool Integration Plugins

This directory contains plugins that enhance the editing experience with specialized tools and functionality. These plugins provide focused, purpose-built features that extend the core editor capabilities.

## Overview

The tools module is organized into individual plugin configurations and specialized subdirectories:

### Core Tool Plugins

| Plugin | File | Description |
|--------|------|-------------|
| **autopairs** | `autopairs.lua` | Intelligent auto-pairing with LaTeX/Lean support |
| **gitsigns** | `gitsigns.lua` | Git integration with inline diff and blame |
| **firenvim** | `firenvim.lua` | Browser textarea integration |
| **mini** | `mini.lua` | Collection of mini.nvim modules (comment, ai, cursorword) |
| **surround** | `surround.lua` | Text surrounding and manipulation |
| **yanky** | `yanky.lua` | Enhanced yank/paste with history |
| **todo-comments** | `todo-comments.lua` | TODO comment highlighting and navigation |
| **luasnip** | `luasnip.lua` | Snippet engine configuration |

### Specialized Subdirectories

- **[`autolist/`](autolist/README.md)** - Smart list handling for markdown and note-taking
- **[`snacks/`](snacks/README.md)** - Collection of UI enhancements and utilities

## Plugin Categories

### Text Manipulation & Editing
- **autopairs**: Advanced bracket and quote pairing with language-specific rules
  - LaTeX dollar sign pairs (`$...$`) with proper spacing
  - Lean unicode mathematical symbols (`⟨⟩`, `«»`, `⟪⟫`, `⦃⦄`)
  - Treesitter integration for context-aware pairing
  - blink.cmp integration via community workaround

- **mini**: Essential editing enhancements
  - `mini.comment`: Smart commenting for all filetypes
  - `mini.ai`: Enhanced text objects (functions, classes, blocks)
  - `mini.cursorword`: Highlight word under cursor

- **surround**: Text object manipulation
  - Add, delete, change surrounding characters
  - Works with quotes, brackets, XML tags, and custom delimiters

- **yanky**: Advanced clipboard management
  - Yank history with telescope integration
  - Smart paste behavior
  - Visual feedback for yank operations

### List & Document Management
- **autolist**: Intelligent list handling
  - Auto-increment numbered lists
  - Seamless list type cycling
  - Markdown and Neorg support
  - Smart indentation and continuation

- **todo-comments**: Project-wide TODO management
  - Highlight TODO, FIXME, NOTE, HACK, WARNING comments
  - Telescope integration for project-wide search
  - Configurable keywords and colors

### Development & Git Integration
- **gitsigns**: Comprehensive git integration
  - Inline diff indicators in sign column
  - Git blame information
  - Hunk navigation and preview
  - Stage/unstage hunks directly in editor

- **firenvim**: Browser-editor bridge
  - Edit textareas in external applications
  - Seamless Neovim integration in web browsers
  - Automatic filetype detection

### Code Completion & Snippets
- **luasnip**: Advanced snippet engine
  - Custom snippet definitions
  - Dynamic snippet expansion
  - Integration with completion engines

## Configuration Architecture

The tools module uses a structured loading system:

```lua
-- lua/neotex/plugins/tools/init.lua
-- Safe loading with error handling
local function safe_require(module)
  -- Validates plugin specs and handles errors gracefully
end

-- Loads all tool plugins with validation
return {
  gitsigns_module,
  firenvim_module,
  snacks_module,
  autolist_module,
  mini_module,
  surround_module,
  todo_comments_module,
  yanky_module,
  autopairs_module,
  luasnip_module,
}
```

## Key Features

### Academic & Technical Writing
- **LaTeX Support**: Dollar sign pairs, spacing rules, backtick conversion
- **Mathematical Notation**: Unicode symbols for Lean theorem proving
- **Document Structure**: Smart list management and TODO tracking

### Development Workflow
- **Git Integration**: Inline diffs, blame, and hunk management
- **Code Navigation**: Enhanced text objects and cursor highlighting
- **Snippet System**: Custom code templates and expansion

### User Experience
- **Browser Integration**: Edit web forms in Neovim
- **Clipboard Enhancement**: Persistent yank history and smart pasting
- **Visual Feedback**: Clear indicators for git changes and highlights

## Usage Examples

### Autopairs (LaTeX/Lean)
```latex
% LaTeX math mode
$E = mc^2$           % Auto-paired dollars
\frac{1}{2}         % Smart bracket spacing
```

```lean
-- Lean mathematical symbols
theorem example : ⟨a, b⟩ = ⟨b, a⟩ := by sorry
def func : «input» → «output» := sorry
```

### Git Integration
```lua
-- Keymap examples (see which-key configuration)
<leader>gp  -- Preview hunk
<leader>gs  -- Git status
<leader>gl  -- Line blame
```

### List Management
```markdown
1. First item
2. Second item    -- Auto-incremented
   - Nested item  -- Smart cycling
   - Another item
3. Continue...    -- Smart continuation
```

## Plugin Verification

To verify tools plugins are properly loaded:

```vim
:luafile scripts/check_plugins.lua
```

This shows the TOOLS category with all configured plugins. See [`scripts/README.md`](../../../scripts/README.md) for complete script documentation.

## Dependencies

### External Dependencies
- **Git**: Required for gitsigns functionality
- **Node.js**: Required for firenvim browser integration
- **Telescope**: Required for yanky history and todo-comments search

### Internal Dependencies
- **Treesitter**: Enhances autopairs and mini.ai functionality
- **LSP**: Provides context for intelligent pairing
- **Which-key**: Provides keybinding documentation

## Related Documentation

- [Main Plugins README](../README.md) - Plugin system overview
- [Editor Plugins](../editor/README.md) - Core editing functionality
- [LSP Configuration](../lsp/README.md) - Language server setup
- [UI Plugins](../ui/README.md) - Interface enhancements

For detailed configuration of specialized components, see the subdirectory documentation:
- [Autolist Documentation](autolist/README.md)
- [Snacks Documentation](snacks/README.md)