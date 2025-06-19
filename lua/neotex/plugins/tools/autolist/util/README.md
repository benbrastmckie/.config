# Autolist Utilities

This directory contains utility modules for the autolist plugin, which provides intelligent list management in Markdown and other text formats.

## File Structure

```
util/
├── README.md           # This documentation
├── init.lua           # Main initialization module
├── commands.lua       # Command definitions
├── integration.lua    # Plugin integration layer
├── list_operations.lua # Core list manipulation
└── utils.lua          # General utility functions
```

## Files

### init.lua
Main initialization and coordination module for autolist utilities.

**Features:**
- Utility module loading and setup
- Integration coordination between components
- Common configuration management
- Shared state initialization

### commands.lua
Command definitions and implementations for autolist functionality.

**Features:**
- `:AutolistEnable` / `:AutolistDisable` - Toggle autolist functionality
- `:AutolistRecalculate` - Recalculate list item numbers
- `:AutolistNewBullet` - Insert new bullet at current level
- `:AutolistChangeMarker` - Change list marker type
- Buffer-specific command registration

### integration.lua
Integration layer for autolist with other plugins and Neovim features.

**Features:**
- LSP integration for semantic list understanding
- Completion system integration
- Treesitter integration for syntax-aware list handling
- Plugin conflict resolution and compatibility

### list_operations.lua
Core list manipulation operations and algorithms.

**Features:**
- List item insertion and deletion
- Automatic numbering and renumbering
- Indentation level management
- List type detection and conversion
- Marker type cycling (-, *, +, numbered)

### utils.lua
General utility functions supporting list operations.

**Features:**
- Text parsing and pattern matching
- Position calculation and cursor management
- Configuration option handling
- Error handling and validation
- Cross-platform path and encoding utilities

## Functionality

### Intelligent List Management
- **Auto-continuation**: Pressing Enter in a list automatically creates new items
- **Smart indentation**: Tab/Shift-Tab adjusts list item levels
- **Marker cycling**: Change between different list marker types
- **Number management**: Automatic renumbering of ordered lists

### List Types Supported
- **Unordered lists**: `- item`, `* item`, `+ item`
- **Ordered lists**: `1. item`, `1) item`, `a. item`, `i. item`
- **Task lists**: `- [ ] todo`, `- [x] done`
- **Custom markers**: User-defined list patterns

### Context Awareness
- **File type detection**: Adapts to Markdown, plain text, etc.
- **Syntax awareness**: Uses Treesitter for accurate list detection
- **Mixed list handling**: Supports different list types in same document
- **Nested lists**: Proper handling of multi-level list structures

## Configuration Integration

### With Autolist Main Plugin
The utilities extend the base autolist functionality:
- Enhanced list detection algorithms
- Additional commands and keybindings
- Improved compatibility with other plugins
- Custom configuration options

### With Text Processing
- **Markdown integration**: Works seamlessly with Markdown syntax
- **Academic writing**: Supports structured document outlines
- **Note-taking**: Enhances list-based note organization
- **Task management**: Integrates with TODO and task tracking

## Related Configuration
- [autolist/init.lua](../init.lua) - Main autolist plugin configuration
- [text/markdown-preview.lua](../../text/markdown-preview.lua) - Markdown integration
- [editor/treesitter.lua](../../editor/treesitter.lua) - Syntax support

## Navigation

- [← Autolist Plugin](../README.md)
- [← Tools Plugins](../../README.md)