# Tool Integration Plugins

This directory contains plugins that enhance the editing experience with specialized tools and functionality. These plugins provide focused, purpose-built features that extend the core editor capabilities.

## File Structure

```
tools/
├── README.md           # This documentation
├── init.lua           # Tools plugins loader
├── autopairs.lua      # Intelligent auto-pairing
├── gitsigns.lua       # Git integration
├── firenvim.lua       # Browser integration
├── mini.lua           # Mini plugin collection
├── surround.lua       # Text surrounding
├── yanky.lua          # Enhanced yank/paste
├── todo-comments.lua  # TODO comment management
├── luasnip.lua        # Snippet engine
├── autolist/          # Smart list handling
│   ├── README.md      # Autolist documentation
│   ├── init.lua       # Main autolist plugin
│   └── util/          # Autolist utilities
├── snacks/            # UI enhancements
│   ├── README.md      # Snacks documentation
│   ├── init.lua       # Main snacks configuration
│   ├── dashboard.lua  # Dashboard setup
│   └── utils.lua      # Snacks utilities
└── himalaya/          # Email client integration
    ├── README.md      # Himalaya documentation
    ├── INSTALLATION.md # Complete setup guide
    ├── init.lua       # Main plugin interface
    ├── config.lua     # Configuration management
    ├── commands.lua   # Command definitions
    ├── ui.lua         # Email interface
    ├── picker.lua     # Telescope integration
    └── utils.lua      # CLI utilities
```

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
- **[`himalaya/`](himalaya/README.md)** - Complete email client integration with local storage

## Plugin Categories

### Text Manipulation & Editing
- **autopairs**: Advanced bracket and quote pairing with language-specific rules
  - LaTeX dollar sign pairs (`$...$`) with proper spacing
  - Lean unicode mathematical symbols (`⟨⟩`, `«»`, `⟪⟫`, `⦃⦄`)
  - Treesitter integration for context-aware pairing

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

### Communication & Email
- **himalaya**: Complete email client integration
  - Multi-account email management (personal, work)
  - Local Maildir storage with automatic IMAP sync
  - Rich email interface with floating windows
  - Telescope integration for folders and accounts
  - Offline email access and composition
  - OAuth2 authentication with secure keyring storage

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
  himalaya_module,
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
- **Email Management**: Complete email workflow without leaving the editor

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

### Email Management
```lua
-- Keymap examples for email workflow
<leader>me  -- Open email list
<leader>mw  -- Compose new email
<leader>mf  -- Browse folders
<leader>ma  -- Switch accounts

-- Within email list
<CR>        -- Read email
gr          -- Reply
gf          -- Forward
gD          -- Delete
```

## Completion Integration

### Autopairs and Completion System

Text pairing functionality is provided by two complementary systems:

- **nvim-autopairs**: Handles language-specific custom rules for LaTeX and Lean
- **blink.cmp auto-brackets**: Provides bracket completion for function calls and completions

#### Configuration
```lua
-- autopairs.lua: Custom language rules
autopairs.add_rules({
  Rule("$", "$", "tex"),                    -- LaTeX math mode
  Rule("⟨", "⟩", "lean"),                  -- Lean angle brackets
  Rule("«", "»", "lean"),                   -- Lean guillemets
  Rule("⟪", "⟫", "lean"),                  -- Lean double angle brackets
  Rule("⦃", "⦄", "lean"),                  -- Lean white curly brackets
})

-- blink-cmp.lua: Auto-brackets for completions
completion = {
  accept = {
    auto_brackets = {
      enabled = true,
      blocked_filetypes = { 'tex', 'latex', 'lean' }
    }
  }
}
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
- **Himalaya CLI**: Required for email client functionality
- **mbsync**: Required for email synchronization
- **GNOME Keyring**: Required for secure email credential storage

### Internal Dependencies
- **Treesitter**: Enhances autopairs and mini.ai functionality
- **LSP**: Provides context for intelligent pairing
- **Which-key**: Provides keybinding documentation

## Related Documentation

For detailed configuration of specialized components, see the subdirectory documentation:
- [Autolist Documentation](autolist/README.md)
- [Snacks Documentation](snacks/README.md)
- [Himalaya Email Documentation](himalaya/README.md)

## Navigation

- [Autolist Plugin →](autolist/README.md)
- [Snacks Plugin →](snacks/README.md)
- [Himalaya Email →](himalaya/README.md)
- [Editor Plugins →](../editor/README.md)
- [LSP Configuration →](../lsp/README.md)
- [UI Plugins →](../ui/README.md)
- [AI Plugins →](../ai/README.md)
- [Text Plugins →](../text/README.md)
- [← Plugins Overview](../README.md)