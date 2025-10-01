# AI Claude Commands

Command discovery and management for Claude Code integration. This module provides a hierarchical Telescope picker for browsing and executing Claude commands from both project-local and global command directories.

## Modules

### picker.lua
Main Telescope picker implementation for Claude commands. Creates a hierarchical display with primary commands at the top level and dependent commands indented below. Supports command editing and terminal insertion.

**Key Functions:**
- `show_commands_picker(opts)` - Main function to display the Claude commands picker
- `create_picker_entries(structure)` - Converts command hierarchy to Telescope entries
- `create_command_previewer()` - Custom previewer showing command documentation
- `send_command_to_terminal(command)` - Inserts command into Claude Code terminal (command only, no placeholders)
- `edit_command_file(command)` - Opens command markdown file in buffer (copies global commands to local first)

**Features:**
- Two-level hierarchy (primary → dependent commands)
- Commands with multiple parents appear under each parent
- Custom previewer with markdown rendering and command metadata
- Local vs global command indicators (`*` prefix for local commands)
- Smart command insertion (opens Claude Code if needed, uses feedkeys for reliable input)
- Load command locally with dependencies (`<C-l>` keybinding)
- Automatic copying of global commands when editing (`<C-e>` keybinding)
- Picker refresh after loading to show updated status

### parser.lua
Command file discovery and metadata parsing. Scans both project-local and global `.claude/commands/` directories for markdown files and extracts standardized frontmatter metadata to build command hierarchy.

**Key Functions:**
- `scan_commands_directory(commands_dir)` - Discovers all .md files in commands directory
- `parse_command_file(filepath)` - Extracts metadata from individual command file
- `parse_all_commands(commands_dir)` - Parses all commands in directory
- `parse_with_fallback(project_dir, global_dir)` - Merges commands from local and global directories
- `build_hierarchy(commands)` - Creates two-level primary/dependent structure
- `get_command_structure(commands_dir)` - Main entry point for organized command data (auto-detects both directories)

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

## Command Directories

The system searches for commands in two locations:

### Local Commands (Project-Specific)
- **Location**: `{project}/.claude/commands/`
- **Priority**: High (overrides global commands with same name)
- **Indicator**: Shown with `*` prefix in picker
- **Use Case**: Project-specific customizations and commands

### Global Commands (Fallback)
- **Location**: `~/.config/.claude/commands/`
- **Priority**: Low (used when no local version exists)
- **Indicator**: No prefix in picker
- **Use Case**: Common commands available across all projects

### Command Resolution
1. Parser checks project's `.claude/commands/` directory first
2. Then checks `~/.config/.claude/commands/` for additional commands
3. Local commands override global ones with the same name
4. All unique commands from both directories are available

### Editing and Loading Behavior

#### Creating New Commands (`<C-n>`)
When pressing `<C-n>` to create a new command:
- **Opens Claude Code**: Launches Claude Code if not already open
- **Inserts prompt**: Automatically inserts "Create a new claude-code command in the {project}/.claude/commands/ directory called "
- **User provides name**: User types the command name and description
- **Claude generates**: Claude creates the command file with proper metadata
- **Picker closes**: Focus shifts to Claude Code for command creation
- **Re-open picker**: Use `:ClaudeCommands` to see the new command after creation

#### Loading Commands (`<C-l>`)
When pressing `<C-l>` to load a command:
- **Local commands**: No action needed (already local)
- **Global commands**: Copies to project's `.claude/commands/`
- **Dependent commands**: Recursively copies all dependencies
- **Preserves existing**: Does not overwrite if local version exists
- **Picker refresh**: Automatically refreshes to show updated `*` markers
- **Picker state**: Remains open for continued browsing

#### Updating Commands (`<C-u>`)
When pressing `<C-u>` to update a command:
- **Purpose**: Overwrites local version with latest global version
- **Global source**: Updates from `~/.config/.claude/commands/`
- **Dependent commands**: Also updates dependencies if they exist globally
- **Force overwrite**: Replaces local version even if modified
- **Picker refresh**: Automatically refreshes to show updated content
- **Picker state**: Remains open for continued browsing

#### Saving to Global (`<C-s>`)
When pressing `<C-s>` to save a command globally:
- **Purpose**: Share local customizations across all projects
- **Requirement**: Command must be local (marked with `*`)
- **Global destination**: Saves to `~/.config/.claude/commands/`
- **Dependent commands**: Also saves local dependencies to global
- **Overwrite behavior**: Replaces existing global version if present
- **Error handling**: Shows error notification if command is not local
- **Picker refresh**: Automatically refreshes after saving
- **Picker state**: Remains open for continued browsing

#### Batch Loading (`[Load All Commands]`)
When selecting the `[Load All Commands]` entry:
- **Scans**: All global commands in ~/.config/.claude/commands/
- **Copies**: Global commands not present locally (new commands)
- **Replaces**: Local commands that have matching global versions
- **Preserves**: Local commands without global equivalents (local-only commands)
- **Confirmation**: Shows yes/no dialog with operation counts before proceeding
- **Refreshes**: Picker automatically refreshes to show updated status
- **Reports**: Number of commands loaded and replaced

**Important**: This operation will overwrite existing local commands with global
versions (same behavior as `<C-u>` for individual commands). Local-only commands
are never touched.

#### Editing Commands (`<C-e>`)
When pressing `<C-e>` to edit a command:
- **Automatic loading**: First loads command locally (same as `<C-l>`)
- **Local commands**: Opens the local file directly
- **Global commands in .config**: Opens the global file directly after loading
- **Global commands in other projects**: Copies to local project first, then opens the copy
- **Picker state**: Closes after opening file for editing

## Integration

### User Commands
- `:ClaudeCommands` - Opens the Claude commands picker

### Keybindings (in picker)
- `<CR>` - Insert command into Claude Code terminal (command only, no argument placeholders)
  - Opens Claude Code if not already running
  - Uses feedkeys for reliable command insertion
  - Special action for `[Load All Commands]`: Copies all global commands to local directory
- `<C-n>` - Create new command with Claude Code
  - Opens Claude Code (if not already open)
  - Inserts prompt: "Create a new claude-code command in the {project}/.claude/commands/ directory called "
  - User provides the command name and description
  - Closes picker to focus on Claude Code
- `<C-l>` - Load command locally (with dependencies)
  - Copies global command to project's `.claude/commands/`
  - Recursively copies all dependent commands
  - Preserves existing local version if present
  - Refreshes picker to show new local status with `*` markers
  - Keeps picker open for continued browsing
- `<C-u>` - Update command from global version
  - Overwrites local version with global version from `~/.config/.claude/commands/`
  - Also updates dependent commands if they exist globally
  - Refreshes picker to show updated content
  - Keeps picker open for continued browsing
- `<C-s>` - Save local command to global
  - Copies local command to `~/.config/.claude/commands/` for use across projects
  - Also saves dependent commands if they exist locally
  - Requires command to be local (shows error for global commands)
  - Refreshes picker after saving
  - Keeps picker open for continued browsing
- `<C-e>` - Edit command markdown file in buffer
  - Automatically loads command locally first (same as `<C-l>`)
  - Opens the local copy for editing
  - Closes picker after opening file
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

The picker displays a two-level hierarchy with local/global indicators:

```
[Keyboard Shortcuts]          Help                             [Special]
[Load All Commands]           Copy all global commands locally [Special]

* plan                        Create implementation plans      [Local]
  ├─ list-reports            List available research reports
  └─ update-plan             Update existing implementation plan

  implement                   Execute implementation plans     [Global]
  ├─ list-plans              List implementation plans
  ├─ list-summaries          List implementation summaries
  └─ update-plan             Update existing implementation plan

* report                      Create research reports         [Local]
  ├─ list-reports            List available research reports
  └─ update-report           Update existing research report
```

### Special Entries
- **`[Keyboard Shortcuts]`**: Shows help for picker keybindings
- **`[Load All Commands]`**: Batch copies all global commands to local directory

### Command Indicators
- **`*` prefix**: Indicates a local command (defined in project's `.claude/commands/`)
- **No prefix**: Indicates a global command (from `~/.config/.claude/commands/`)
- Primary commands appear at the root level, with their dependent commands indented below
- Commands that serve multiple parents (like `update-plan`) appear under each parent for easy discovery

## Error Handling
- Graceful fallback when neither local nor global `.claude/commands/` directories exist
- Robust YAML frontmatter parsing with validation
- Terminal detection with automatic Claude Code launching
- Smart command insertion with feedkeys for reliability
- Automatic directory creation when copying global commands to local
- Comprehensive error notifications using `neotex.util.notifications`

## Navigation
- [← Parent Directory](../README.md)