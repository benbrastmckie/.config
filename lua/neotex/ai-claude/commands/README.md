# AI Claude Commands

Command discovery and management for Claude Code integration. This module provides a hierarchical Telescope picker for browsing and executing Claude commands from `.claude/commands/` directory.

## Modules

### picker.lua
Main Telescope picker implementation for Claude commands. Creates a hierarchical display with primary commands at the top level and dependent commands indented below. Supports command editing and terminal insertion.

**Key Functions:**
- `show_commands_picker(opts)` - Main function to display the Claude commands picker
- `create_picker_entries(structure)` - Converts command hierarchy to Telescope entries
- `create_command_previewer()` - Custom previewer showing command documentation
- `send_command_to_terminal(command)` - Inserts command into Claude Code terminal
- `edit_command_file(command)` - Opens command markdown file in buffer

**Features:**
- Two-level hierarchy (primary → dependent commands)
- Commands with multiple parents appear under each parent
- Custom previewer with markdown rendering and command metadata
- Keyboard shortcuts help entry
- Terminal integration with argument placeholder support

### parser.lua
Command file discovery and metadata parsing. Scans `.claude/commands/` directory for markdown files and extracts standardized frontmatter metadata to build command hierarchy.

**Key Functions:**
- `scan_commands_directory(commands_dir)` - Discovers all .md files in commands directory
- `parse_command_file(filepath)` - Extracts metadata from individual command file
- `parse_all_commands(commands_dir)` - Parses all commands in directory
- `build_hierarchy(commands)` - Creates two-level primary/dependent structure
- `get_command_structure(commands_dir)` - Main entry point for organized command data

**Metadata Format:**
Commands use standardized YAML frontmatter:
```yaml
---
command-type: primary | dependent
dependent-commands: cmd1, cmd2  # for primary commands
parent-commands: cmd1, cmd2     # for dependent commands
description: Command description
argument-hint: <arg1> [optional-arg]
allowed-tools: tool1, tool2
---
```

## Integration

### User Commands
- `:ClaudeCommands` - Opens the Claude commands picker

### Keybindings (in picker)
- `<CR>` - Insert command into Claude Code terminal (without execution)
- `<C-e>` - Edit command markdown file in buffer
- `<Escape>` - Close picker

### Configuration
Available in `ai-claude.config.commands`:
```lua
commands = {
  show_dependencies = true,      -- Show dependent commands in hierarchy
  show_help_entry = true,        -- Show keyboard shortcuts help entry
  cache_timeout = 300,           -- Cache parsed commands for 5 minutes
}
```

## Usage Examples

### Basic Usage
```lua
-- Show commands picker
require('neotex.ai-claude').show_commands_picker()

-- Or use the user command
:ClaudeCommands
```

### Integration with ai-claude Module
```lua
local ai_claude = require('neotex.ai-claude')
ai_claude.setup({
  commands = {
    show_dependencies = true,
    show_help_entry = true,
  }
})

-- Commands picker is automatically available after setup
ai_claude.show_commands_picker()
```

## Dependencies
- telescope.nvim - For picker UI and fuzzy finding
- plenary.nvim - File system utilities (telescope dependency)
- claude-code.nvim - For terminal integration (optional, graceful fallback)

## Command Structure

The picker displays a two-level hierarchy:

```
plan                          Create implementation plans
├─ list-reports              List available research reports
└─ update-plan               Update existing implementation plan

implement                     Execute implementation plans
├─ list-plans                List implementation plans
├─ list-summaries            List implementation summaries
└─ update-plan               Update existing implementation plan

report                        Create research reports
├─ list-reports              List available research reports
└─ update-report             Update existing research report
```

Primary commands appear at the root level, with their dependent commands indented below. Commands that serve multiple parents (like `update-plan`) appear under each parent for easy discovery.

## Error Handling
- Graceful fallback when `.claude/commands/` directory doesn't exist
- Robust YAML frontmatter parsing with validation
- Terminal detection with automatic Claude Code launching
- Comprehensive error notifications using `neotex.util.notifications`

## Navigation
- [← Parent Directory](../README.md)