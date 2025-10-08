# AI Claude Commands

Artifact discovery and management for Claude Code integration. This module provides a comprehensive hierarchical Telescope picker for browsing and managing all Claude Code artifacts including commands, agents, hooks, TTS files, templates, libraries, documentation, and configuration. Supports both project-local and global artifact directories with visual categorical organization.

The picker displays categories in logical order with headings at the top: [Commands], [Agents], [Hook Events], [TTS], [Templates], [Lib], [Docs], followed by special entries at the bottom. Each category groups related artifacts hierarchically for easy navigation and discovery.

## Modules

### picker.lua
Main Telescope picker implementation for Claude commands, agents, hooks, and TTS files. Creates a hierarchical display with categorical organization for easy navigation. Supports comprehensive artifact management including commands, agents, hooks, TTS files, templates, libraries, documentation, and configuration.

Categories appear in logical order with headings at the top: [Commands], [Agents], [Hook Events], [TTS], [Templates], [Lib], [Docs], followed by special entries at the bottom. This reversed insertion order ensures categories display in descending sort with headings first.

**Key Functions:**
- `show_commands_picker(opts)` - Main function to display the Claude artifacts picker
- `create_picker_entries(structure)` - Converts artifact hierarchy to Telescope entries with categorical headings (reversed insertion for top-down display)
- `create_command_previewer()` - Custom previewer showing artifact documentation and README content for category headings
- `send_command_to_terminal(command)` - Inserts command into Claude Code terminal (command only, no placeholders)
- `edit_command_file(command)` - Opens command markdown file in buffer (copies global commands to local first)
- `load_all_globally()` - Batch syncs all artifact types from global to local directory

**Features:**
- Categorical organization with visual headings at top ([Commands], [Agents], [Hook Events], [TTS], [Templates], [Lib], [Docs])
- Standalone agents section for agents not nested under commands
- Agent cross-reference display showing parent commands in preview pane
- Category headings preview README content from associated .claude/ directories
- Two-level hierarchy (primary → dependent commands, events → hooks, commands → agents)
- Commands with multiple parents appear under each parent
- Custom previewer with markdown rendering and artifact metadata
- Local vs global artifact indicators (`*` prefix for local artifacts)
  - Hook events show `*` when ANY associated hook is local
  - Individual artifacts show `*` based on their own location
- Standardized tree character indentation for visual hierarchy
  - Commands/Agents: 1-space indentation
  - Hook Events: 2-space indentation
  - Other artifacts (TTS/Templates/Lib/Docs): 1-space indentation
  - Preview cross-references: 3-space indentation
- Smart command insertion (opens Claude Code if needed, uses feedkeys for reliable input)
- Load artifacts locally with dependencies (`<C-l>` keybinding)
- Save local artifacts to global (`<C-s>` keybinding)
- Universal file editing (`<C-e>` keybinding) - supports all artifact types (Commands, Agents, Templates, Lib, Docs, Hooks, TTS)
- Direct action execution with Enter key
  - Commands: Insert into Claude Code terminal
  - All other artifacts: Open file for editing
- Native preview scrolling with Telescope actions
  - `<C-u>`/`<C-d>`: Scroll preview by half page
  - `<C-f>`/`<C-b>`: Scroll preview by full page
  - Works from picker without focus switching
  - 100% reliable with no buffer errors
- Picker refresh after operations to show updated status
- Comprehensive artifact coverage (11 categories: commands, agents, hooks, TTS, templates, libraries, docs, agent protocols, standards, data docs, settings)

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
- **First load** (no local version exists):
  - Silently copies to project's `.claude/commands/`
  - Recursively copies all dependencies
  - Shows `*` marker after refresh
- **Second load** (local version exists):
  - Always shows confirmation dialog with options:
    - "Replace 'X' only" - Overwrites just the selected command
    - "Replace 'X' + N dependent(s): [list]" - Overwrites command and all dependents (if has dependents)
    - Or just "Replace 'X'" if no dependents
  - User can cancel with Esc
- **Picker refresh**: Automatically refreshes to show updated `*` markers
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

#### Batch Loading (`[Load All Artifacts]`)
When selecting the `[Load All Artifacts]` entry:
- **Scans**: All global artifacts in ~/.config/.claude/ (11 categories)
- **Artifact Categories**:
  - Commands (*.md)
  - Agents (*.md)
  - Hooks (*.sh)
  - TTS Files (*.sh from hooks/ and tts/)
  - Templates (*.yaml)
  - Library Utilities (*.sh from lib/)
  - Documentation (*.md from docs/)
  - Agent Protocols (*.md from agents/prompts/, agents/shared/)
  - Standards (*.md from specs/standards/)
  - Data Documentation (README.md from data subdirs)
  - Settings (settings.local.json)
- **README Coverage**: Syncs README.md files from all .claude/ directories
- **Always Shows Sync Strategy Choice**:
  - Displays detailed breakdown: X new, Y conflicts per category
  - **If conflicts exist** (local versions present):
    - Option 1: "Replace all + add new (N total)" - Overwrites all local versions with global
    - Option 2: "Add new only, preserve local (M new)" - Only adds new artifacts, skips all conflicts
  - **If no conflicts** (only new artifacts):
    - Option 1: "Add all new artifacts (N total)" - Adds all new global artifacts
  - User can cancel with Esc (always available)
- **One choice for all**: Selected strategy applies to entire batch of artifacts
- **Preserves**: Local-only artifacts (no global equivalent) - always untouched
- **Refreshes**: Picker automatically refreshes to show updated status
- **Reports**: Number of artifacts loaded with chosen strategy

**Sync Strategies Explained**:
- **Replace all + add new**: Replaces all local versions with global versions + adds new artifacts
- **Add new only, preserve local**: Safe merge - only adds artifacts not already in local .claude/

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
- `<CR>` - Execute action for selected item
  - **Commands**: Insert command into Claude Code terminal
    - Opens Claude Code if not already running
    - Uses feedkeys for reliable command insertion
  - **All other artifacts**: Open file for editing
    - Agents, Docs, Lib, Templates, Hooks, TTS files open directly
  - **Special entries**:
    - `[Load All Artifacts]`: Batch syncs all artifact types
    - `[Keyboard Shortcuts]`: No action (help entry)
- `<C-u>` / `<C-d>` - Scroll preview up/down (half page)
  - Native Telescope preview scrolling
  - Works from picker without focus switching
  - No buffer errors
- `<C-f>` / `<C-b>` - Scroll preview down/up (full page)
  - Alternative scrolling for full-page navigation
  - Same reliable behavior as `<C-u>`/`<C-d>`
- `<Esc>` - Close picker immediately (single press)
- `<C-n>` - Create new command with Claude Code
  - Opens Claude Code (if not already open)
  - Inserts prompt: "Create a new claude-code command in the {project}/.claude/commands/ directory called "
  - User provides the command name and description
  - Closes picker to focus on Claude Code
- `<C-l>` - Load artifact locally (smart confirmation)
  - **First load**: Silently copies global artifact to project's `.claude/` directory with dependencies
  - **Subsequent loads**: Always shows confirmation dialog when local version exists
    - Options: "Replace only", "Replace + dependents", or Cancel
  - Refreshes picker to show new local status with `*` markers
  - Keeps picker open for continued browsing
- `<C-s>` - Save local artifact to global
  - Copies local artifact to `~/.config/.claude/` for use across projects
  - Also saves dependent artifacts if they exist locally
  - Requires artifact to be local (shows error for global artifacts)
  - Refreshes picker after saving
  - Keeps picker open for continued browsing
- `<C-e>` - Edit artifact file in buffer (universal file editing)
  - **Commands**: Automatically loads locally first, then opens for editing
  - **All other types** (Agents/Templates/Lib/Docs/Hooks/TTS): Opens file directly
  - Proper file path escaping for paths with spaces
  - Preserves executable permissions for .sh files
  - Closes picker after opening file

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

### Navigation Workflow Examples

#### Direct Action Execution
Simple one-step workflow for quick actions:

1. **Navigate to desired artifact** using j/k or fuzzy search
2. **Press Return**: Execute action immediately
   - Commands: Insert into Claude Code
   - All others: Open file for editing

**Example: Inserting a Command**
```
1. Type "plan" to filter and highlight /plan command
2. Press Return
3. Command "/plan" inserted into Claude Code terminal
```

**Example: Editing an Agent**
```
1. Navigate to [agent] metrics-specialist
2. Press Return
3. Agent file opens for editing in buffer
```

#### Preview Scrolling with Native Telescope Actions

Use `<C-u>`/`<C-d>` to scroll preview while staying in picker:

**Example: Reading Long Agent Description**
```
1. Navigate to agent with lengthy description
2. Press <C-d> to scroll preview down half page
3. Press <C-d> again to continue scrolling
4. Press <C-u> to scroll back up
5. Press Return to open agent file if desired
```

**Example: Reviewing Category README**
```
1. Navigate to [Commands] heading
2. Preview shows full README.md from .claude/commands/
3. Press <C-d>/<C-u> to scroll through documentation
4. Press j/k to navigate to specific command
5. Press Return to insert command or edit file
```

**Benefits of Native Scrolling**:
- No focus switching required
- 100% reliable with no buffer errors
- Standard Telescope behavior
- Works across all preview types

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

## Artifact Structure

The picker displays a categorized hierarchy with local/global indicators. Categories appear in logical order with headings at the top:

```
[Commands]                    Claude Code slash commands       [Category]

* plan                        Create implementation plans      [Local]
  ├─ [agent] plan-architect  AI planning specialist
  └─ list-reports            List available research reports

  implement                   Execute implementation plans     [Global]
  ├─ [agent] code-writer     AI implementation specialist
  └─ list-plans              List implementation plans

[Agents]                      Standalone AI agents             [Category]

  [agent] metrics-specialist  Performance analysis specialist

[Hook Events]                 Event-triggered scripts          [Category]

* [Hook Event] Stop            After command completion
  ├─ post-command-metrics.sh   Collect command metrics
  └─ tts-notification.sh       Voice notification

[TTS Files]                   Text-to-speech system files     [Category]

* ├─ [config] tts-config.sh    (tts) 15L
  └─ [dispatcher] tts-dispatcher.sh (hooks) 42L

[Templates]                   Workflow templates               [Category]

* ├─ crud-feature.yaml         CRUD feature implementation
  └─ api-endpoint.yaml         API endpoint scaffold

[Lib]                         Utility libraries                [Category]

* ├─ checkpoint-utils.sh       State persistence utilities
  └─ template-parser.sh        Template variable substitution

[Docs]                        Integration guides               [Category]

* ├─ template-system-guide.md  Template system documentation
  └─ api-integration-guide.md  API integration patterns

[Load All Artifacts]          Sync all global artifacts        [Special]
[Keyboard Shortcuts]          Help                             [Special]
```

### Category Order (Top to Bottom)

The picker displays categories in the following order:

1. **[Commands]** - Claude Code slash commands (.md files)
2. **[Agents]** - Standalone AI agents not nested under commands (.md files)
3. **[Hook Events]** - Event-triggered automation scripts (.sh files)
4. **[TTS Files]** - Text-to-speech system configuration and scripts (.sh files)
5. **[Templates]** - Workflow templates (.yaml files) - if exist
6. **[Lib]** - Utility libraries (.sh files) - if exist
7. **[Docs]** - Integration guides (.md files) - if exist
8. **[Load All Artifacts]** - Special entry for batch synchronization
9. **[Keyboard Shortcuts]** - Special entry for help

Categories only appear when artifacts of that type exist. Special entries always appear at the bottom.

### Agent Cross-Reference Display

When navigating to an agent in the picker, the preview pane displays which commands use that agent:

**Data Source**: The parser (`parser.lua`) populates the `agent.parent_commands` array during command scanning by detecting agent references in command metadata.

**Preview Format**:
```
Agent: plan-architect

Description: AI planning specialist

Allowed Tools: ReadFile, WriteFile, SlashCommand

Commands that use this agent:
├─ plan
└─ revise

File: /home/user/.claude/agents/plan-architect.md

[Local] Local override
```

**Tree Character Formatting**:
- `├─` for intermediate commands
- `└─` for the last command in the list
- Consistent with the hierarchical display style used throughout the picker

**Benefits**:
- Discover which workflows utilize an agent
- Understand agent dependencies without opening files
- Navigate between related commands and agents efficiently
- Identify agents suitable for reuse in new commands

### Special Entries
- **`[Load All Artifacts]`**: Batch syncs all artifact types from global directory
- **`[Keyboard Shortcuts]`**: Shows help for picker keybindings

### Category Headings
- **`[Commands]`**: Claude Code slash commands with nested agents and dependents
- **`[Agents]`**: Standalone agents not associated with any command
- **`[Hook Events]`**: Event-triggered automation scripts
- **`[TTS Files]`**: Text-to-speech system configuration and scripts
- **`[Templates]`**: Workflow templates for faster plan creation
- **`[Lib]`**: Utility libraries and shared functions
- **`[Docs]`**: Integration guides and documentation
- **Non-selectable**: Category headings organize artifacts but cannot be selected
- **README Preview**: When navigating to a category heading, the preview pane displays the associated README.md file

#### Category README Preview

Category headings display comprehensive README content in the preview pane:

**Directory Mapping**:
- `[Commands]` → `.claude/commands/README.md`
- `[Agents]` → `.claude/agents/README.md`
- `[Hook Events]` → `.claude/hooks/README.md`
- `[TTS Files]` → `.claude/tts/README.md`
- `[Templates]` → `.claude/templates/README.md`
- `[Lib]` → `.claude/lib/README.md`
- `[Docs]` → `.claude/docs/README.md`

**Path Resolution**:
1. Checks project-local `.claude/{category}/README.md` first
2. Falls back to global `~/.config/.claude/{category}/README.md`
3. Uses first readable file found

**Preview Features**:
- Markdown syntax highlighting for README content
- 150-line preview limit to prevent buffer overflow
- Truncation indicator when README exceeds limit: `[Preview truncated - showing first 150 of N lines]`
- Graceful fallback to generic text if README not found
- Scrollable preview for navigation through content

**Benefits**:
- Immediate access to category documentation while browsing
- Context-aware help for each artifact type
- No need to leave picker to view documentation
- Professional markdown rendering with syntax highlighting

### Artifact Indicators

#### Local vs Global Indicators
- **`*` prefix**: Indicates a local artifact (defined in project's `.claude/`)
- **No prefix**: Indicates a global artifact (from `~/.config/.claude/`)

**Hook Event Local Indicators**:
- Hook events show `*` prefix when ANY hook associated with that event is local
- Individual hooks may be global while the event shows `*` if at least one hook is local
- This indicates the event has local customization even if not all hooks are local

**Example**:
```
* [Hook Event] Stop            After command completion
  ├─ post-command-metrics.sh   Collect command metrics (local)
  └─ tts-notification.sh       Voice notification (global)
```

The event shows `*` because `post-command-metrics.sh` is local, even though `tts-notification.sh` is global.

#### Display Hierarchy
- Primary commands appear at the root level, with their dependent commands indented below
- Hooks appear indented under their event triggers
- Agents appear indented under their parent commands
- Commands that serve multiple parents (like `update-plan`) appear under each parent for easy discovery

#### Tree Character Indentation

The picker uses standardized indentation patterns for visual hierarchy:

**Commands and Agents** (1-space indentation):
```
* plan                        Create implementation plans
  ├─ [agent] plan-architect  AI planning specialist
  └─ list-reports            List available research reports
```

**Hook Events** (2-space indentation):
```
* [Hook Event] Stop            After command completion
  ├─ post-command-metrics.sh   Collect command metrics
  └─ tts-notification.sh       Voice notification
```

**Other Artifacts** (1-space indentation):
- TTS Files: `* ├─ [config] tts-config.sh`
- Templates: `* ├─ crud-feature.yaml`
- Lib: `* ├─ checkpoint-utils.sh`
- Docs: `* ├─ template-system-guide.md`

**Preview Cross-References** (3-space indentation):
```
Commands that use this agent:
   ├─ plan
   └─ revise
```

The indentation creates consistent visual hierarchy while distinguishing different artifact categories.

## Error Handling
- Graceful fallback when neither local nor global `.claude/commands/` directories exist
- Robust YAML frontmatter parsing with validation
- Terminal detection with automatic Claude Code launching
- Smart command insertion with feedkeys for reliability
- Automatic directory creation when copying global commands to local
- Comprehensive error notifications using `neotex.util.notifications`

## Navigation
- [← Parent Directory](../README.md)