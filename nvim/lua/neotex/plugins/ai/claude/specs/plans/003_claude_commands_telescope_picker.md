# Claude Commands Telescope Picker Implementation Plan (Refactor)

## Metadata
- **Date**: 2025-09-29
- **Plan Type**: Refactor/New Feature Implementation
- **Feature**: Neovim command for displaying Claude commands in hierarchical Telescope picker
- **Scope**: Add telescope picker to ai-claude module for browsing and executing Claude commands (new functionality)
- **Estimated Phases**: 5
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/lua/neotex/ai-claude/specs/reports/001_ai_claude_module_analysis.md
- **Plan Number**: 003 (ai-claude module)

## Overview
**This is a refactor/enhancement plan** that adds new command discovery functionality to the existing ai-claude module. The plan implements a Neovim command that displays all Claude commands from `.claude/commands/` in a hierarchical Telescope picker, with proper distinction between primary and dependent commands, supporting command editing and insertion into the Claude Code sidebar.

This addresses the "Command Discovery" gap identified in the ai-claude module analysis and follows established module patterns. While this adds new functionality (commands picker), it builds upon and integrates with the existing ai-claude module structure rather than creating an entirely new system.

## Success Criteria
- [ ] Telescope picker displays all Claude commands from `.claude/commands/`
- [ ] Primary commands appear at top level, dependent commands are indented
- [ ] Commands that are dependencies of multiple parents appear under each parent
- [ ] `<C-e>` mapping opens command markdown file for editing
- [ ] `<CR>` mapping inserts command into Claude Code terminal without executing
- [ ] Proper metadata parsing to identify primary vs dependent commands
- [ ] Clean visual hierarchy in picker display
- [ ] Integration with ai-claude module patterns and utilities

## Technical Design

### Architecture
- New directory: `lua/neotex/ai-claude/commands/` for command-related modules
- Core module: `lua/neotex/ai-claude/commands/picker.lua` for Telescope integration
- Parser module: `lua/neotex/ai-claude/commands/parser.lua` for command file analysis
- Integration with existing `ai-claude/utils/claude-code.lua` for terminal interaction
- Extension of `ai-claude/init.lua` to expose new functionality
- Follow notification patterns using `neotex.util.notifications`

### Command Classification
- **Primary Commands**: Marked with `command-type: primary` in frontmatter
- **Dependent Commands**: Marked with `command-type: dependent` and `parent-commands: cmd1, cmd2`
- **Detection Method**: Parse standardized frontmatter metadata for reliable classification

### Standardized Metadata Format
All commands now include standardized frontmatter:
```yaml
---
command-type: primary | dependent
dependent-commands: cmd1, cmd2  # for primary commands
parent-commands: cmd1, cmd2     # for dependent commands
---
```

### Integration Patterns (from ai-claude analysis)
- **Module Structure**: Follow separation of concerns (core/ui/utils)
- **Error Handling**: Use `neotex.util.notifications` with categories (ERROR, WARNING, INFO, USER_ACTION)
- **Configuration**: Extend `ai-claude/config.lua` with command picker settings
- **Command Registration**: Follow pattern from `worktree.lua` using `vim.api.nvim_create_user_command`
- **Telescope Patterns**: Follow `ui/pickers.lua` and `worktree.lua` telescope implementations
- **Keybinding Integration**: Add `<leader>ac` to which-key.lua alongside existing ai-claude mappings (`<leader>as`, `<leader>aw`, etc.)

### Current Command Structure
**Primary Commands:**
- `/plan` - Create implementation plans → `list-reports`, `update-plan`
- `/implement` - Execute plans → `list-plans`, `update-plan`, `list-summaries`
- `/report` - Create research reports → `update-report`, `list-reports`
- `/test` - Run project tests
- `/setup` - Setup CLAUDE.md → `validate-setup`

**Dependent Commands:**
- `/list-plans` ← `implement`
- `/list-reports` ← `plan`, `report`
- `/list-summaries` ← `implement`
- `/update-plan` ← `plan`, `implement`
- `/update-report` ← `report`, `implement`
- `/validate-setup` ← `setup`
- `/test-all` ← `test`, `implement`

### Data Flow
1. Scan `.claude/commands/` directory for all markdown files
2. Parse standardized frontmatter metadata for command classification
3. Build simple two-level hierarchy (primary → dependents)
4. Generate Telescope entries with indentation for dependents
5. Handle user actions (edit/insert) through ai-claude utilities

## Implementation Phases

### Phase 1: Command Discovery and Parsing [COMPLETED]
**Objective**: Create robust command file parsing and metadata extraction
**Complexity**: Medium

Tasks:
- [x] Create `lua/neotex/ai-claude/commands/` directory
- [x] Implement `lua/neotex/ai-claude/commands/parser.lua` module
- [x] Function to scan `.claude/commands/` directory for markdown files
- [x] Parse standardized frontmatter metadata:
  - `command-type` (primary/dependent)
  - `dependent-commands` (for primary commands)
  - `parent-commands` (for dependent commands)
  - `allowed-tools`, `argument-hint`, `description`
- [x] Extract command name from filename
- [x] Create two-level hierarchy data structure (primary -> dependents)

Testing:
- ✅ Verified all commands are discovered (13 files found)
- ✅ Tested metadata extraction accuracy
- ✅ Validated dependency detection and hierarchy building

### Phase 2: Two-Level Hierarchy Building [COMPLETED]
**Objective**: Build simple two-level hierarchical structure
**Complexity**: Low

Tasks:
- [x] Group commands by type (primary vs dependent)
- [x] For each primary command, list its dependent commands underneath
- [x] For dependent commands with multiple parents, duplicate under each parent
- [x] Sort primary commands alphabetically
- [x] Sort dependent commands alphabetically under each primary
- [x] Create simple tree structure for display

Testing:
- ✅ Tested with commands having multiple parent dependencies (all working correctly)
- ✅ Verified proper two-level grouping
- ✅ Checked alphabetical sorting within each level

### Phase 3: Telescope Picker Implementation [COMPLETED]
**Objective**: Create interactive Telescope picker with hierarchical display
**Complexity**: Medium

Tasks:
- [x] Create `lua/neotex/ai-claude/commands/picker.lua` module
- [x] Implement Telescope picker following `worktree.lua:telescope_sessions()` pattern
- [x] Create entry maker with simple indentation for two-level hierarchy:
  - Primary commands: no indentation
  - Dependent commands: `  ├─ command-name` or `  └─ command-name`
- [x] Add custom previewer showing command documentation (like `worktree.lua:1683-1726`)
- [x] Configure finder with flattened command entries
- [x] Add keyboard shortcuts help entry (following worktree pattern)
- [x] Set prompt title "Claude Commands" with proper layout

Testing:
- ✅ Tested picker display with hierarchical structure (5 primary, 8 dependent commands)
- ✅ Verified indentation renders correctly with ├─ and └─ characters
- ✅ Implemented custom previewer with markdown rendering

### Phase 4: Action Mappings and Terminal Integration
**Objective**: Implement keybinding actions for editing and command insertion
**Complexity**: High

Tasks:
- [ ] Implement `<C-e>` mapping to open command file in buffer using `vim.cmd.edit`
- [ ] Create function to send command to Claude Code terminal
- [ ] Use `ai-claude/utils/claude-code.lua` patterns for terminal interaction
- [ ] Implement `<CR>` mapping for command insertion without execution
- [ ] Detect terminal buffer using claude-code plugin patterns
- [ ] Use `vim.api.nvim_chan_send` for text insertion (following worktree.lua:1777)
- [ ] Handle edge cases with notification system
- [ ] Add support for command argument placeholders

Testing:
- Test editing command files
- Verify command insertion into terminal
- Test with various terminal states
- Verify error notifications display correctly

### Phase 5: User Command Registration and Polish
**Objective**: Register user command and refine user experience
**Complexity**: Low

Tasks:
- [ ] Add `show_commands_picker` function to `ai-claude/init.lua` public API
- [ ] Register `ClaudeCommands` user command following worktree pattern
- [ ] Add configuration options to `ai-claude/config.lua`:
  - `commands.show_dependencies` (default: true)
  - `commands.show_help_entry` (default: true)
- [ ] Implement error handling with notifications for missing directory
- [ ] Create README.md in commands/ directory documenting the module
- [ ] Define keybinding `<leader>ac` for commands picker in which-key.lua (alongside other ai-claude keybindings)

Testing:
```lua
:ClaudeCommands
-- Verify picker opens with all commands
-- Test all keybindings work as expected
-- Check error handling for edge cases
-- Verify configuration options work
```

## Testing Strategy
1. Unit tests for command parsing and dependency resolution
2. Integration tests for Telescope picker functionality
3. End-to-end tests for complete workflow
4. Manual testing of all user interactions
5. Performance testing with large command sets

## Documentation Requirements
- Create README.md in `ai-claude/commands/` directory
- Add inline documentation to new modules following ai-claude patterns
- Document integration with ai-claude in main module documentation
- Document command metadata format for custom commands
- Update ai-claude/init.lua module documentation

## Dependencies
- telescope.nvim (already available in Neovim config)
- plenary.nvim (telescope dependency)
- Existing ai-claude module infrastructure
- claude-code.nvim plugin for terminal interaction

## Notes
- Consider caching parsed command data for performance
- May want to add fuzzy filtering on command descriptions
- Could extend to support command categories in future
- Ensure compatibility with existing Claude Code terminal instances
- Consider adding command execution history
- Follow ai-claude module patterns for notifications and error handling
- Use existing ai-claude utilities where possible

## Implementation Details from Module Analysis

### Key Patterns to Follow
1. **Telescope Picker Structure** (from worktree.lua:565-907):
   - Use descending sorting strategy
   - Add keyboard shortcuts help entry
   - Implement custom previewer with markdown support
   - Handle multiple action mappings (select, edit, delete)

2. **Terminal Integration** (from worktree.lua:1777):
   ```lua
   vim.api.nvim_chan_send(
     vim.api.nvim_buf_get_option(buf, "channel"),
     command_text .. "\n"
   )
   ```

3. **Notification Pattern** (from worktree.lua:226-251):
   ```lua
   local notify = require('neotex.util.notifications')
   notify.editor(message, notify.categories.USER_ACTION, metadata)
   ```

4. **Command Registration** (from worktree.lua:1059-1087):
   ```lua
   vim.api.nvim_create_user_command("ClaudeCommands",
     M.show_commands_picker,
     { desc = "Browse Claude commands" })
   ```

5. **Configuration Extension** (from config.lua):
   ```lua
   commands = {
     show_dependencies = true,
     show_help_entry = true,
     cache_timeout = 300, -- 5 minutes
   }
   ```