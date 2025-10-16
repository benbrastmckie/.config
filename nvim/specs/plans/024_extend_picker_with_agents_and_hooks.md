# Extend Command Picker with Agents and Hooks Implementation Plan

## Metadata
- **Date**: 2025-10-01
- **Feature**: Extend `<leader>ac` picker to include agents and hooks with dependency tracking
- **Scope**: Parser extensions, picker modifications, file management, enhanced Load All Commands
- **Estimated Phases**: 6
- **Complexity**: High (17-24 hours estimated)
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/specs/reports/034_extend_command_picker_with_agents_and_hooks.md

## Overview

Extend the existing `<leader>ac` command picker to provide complete visibility into the `.claude/` infrastructure by adding:

1. **Agent Display**: Show all agents from `.claude/agents/` listed under the commands that call them
2. **Hook Display**: Show all hooks from `.claude/hooks/` grouped by the hook events that trigger them
3. **Enhanced Load All**: Extend `[Load All Commands]` to synchronize commands, agents, and hooks from `~/.config/.claude/`

The implementation maintains the existing two-level hierarchy using tree characters (├─, └─) and supports all existing keyboard shortcuts (Ctrl-l, Ctrl-u, Ctrl-s, Ctrl-e) for agents and hooks.

### Current State
- Picker displays 18 commands in two-level hierarchy (picker.lua:20-102)
- Parser scans `.claude/commands/` only (parser.lua)
- Load All handles commands only (picker.lua:427-569)

### Target State
- Picker displays commands + agents (under parent commands) + hooks (under events)
- Parser scans `.claude/commands/`, `.claude/agents/`, `.claude/hooks/`
- Load All synchronizes all three artifact types
- Unified file management (load, update, save) for all types

## Success Criteria
- [ ] Parser scans and parses agents and hooks correctly
- [ ] Agents appear under commands that use them in picker
- [ ] Hooks appear under hook events in picker
- [ ] Tree characters (├─, └─) display correctly for all artifact types
- [ ] Keyboard shortcuts (Ctrl-l, Ctrl-u, Ctrl-s) work for agents and hooks
- [ ] Load All synchronizes commands, agents, and hooks
- [ ] Preview displays agent and hook information correctly
- [ ] Local indicator (*) shows for local agents and hooks
- [ ] All existing command picker functionality preserved

## Technical Design

### Architecture Decisions

#### Parser Extensions
- Add `scan_agents_directory()` to parse `.claude/agents/*.md` files
- Add `scan_hooks_directory()` to parse `.claude/hooks/*.sh` files
- Add `build_agent_dependencies()` to map commands → agents
- Add `build_hook_dependencies()` to map events → hooks
- Maintain existing command parsing logic

#### Data Structures
```lua
-- Agent structure
agent = {
  name = "code-writer",
  description = "Specialized in writing...",
  allowed_tools = {"Read", "Write", ...},
  filepath = "/path/to/agent.md",
  is_local = true|false,
  parent_commands = {"orchestrate", "implement"}
}

-- Hook structure
hook = {
  name = "tts-dispatcher.sh",
  description = "Central dispatcher for...",
  filepath = "/path/to/hook.sh",
  is_local = true|false,
  events = {"Stop", "SessionStart", ...}
}

-- Hook event structure
hook_event = {
  name = "Stop",
  description = "Triggered after command completion",
  hooks = {hook1, hook2, ...}
}
```

#### Entry Types
Extend picker entries with new types:
- `entry_type = "command"` (existing)
- `entry_type = "agent"` (new - appears under commands)
- `entry_type = "hook"` (new - appears under events)
- `entry_type = "hook_event"` (new - event header)

### Component Interactions

```
parser.lua
├─ scan_agents_directory() → agent list
├─ scan_hooks_directory() → hook list
├─ build_agent_dependencies() → command→agent map
└─ build_hook_dependencies() → event→hook map

picker.lua
├─ get_command_structure() → calls parser for all types
├─ create_picker_entries() → builds unified entry list
├─ create_command_previewer() → handles all entry types
├─ attach_mappings() → keyboard shortcuts for all types
└─ load_all_globally() → syncs commands + agents + hooks
```

## Implementation Phases

### Phase 1: Parser Extensions [COMPLETED]
**Objective**: Extend parser to scan and parse agents and hooks
**Complexity**: Medium

Tasks:
- [x] Add `scan_agents_directory(agents_dir)` function to parser.lua
  - Scan `.claude/agents/*.md` files
  - Parse YAML frontmatter (description, allowed-tools)
  - Return array of agent metadata
- [x] Add `scan_hooks_directory(hooks_dir)` function to parser.lua
  - Scan `.claude/hooks/*.sh` files
  - Parse header comments for metadata
  - Extract description and hook events
  - Return array of hook metadata
- [x] Add `build_agent_dependencies(commands, agents)` function to parser.lua
  - Parse command files for `subagent_type:` references
  - Build command → agents mapping
  - Build reverse agent → commands mapping
  - Return structured dependency map
- [x] Add `build_hook_dependencies(hooks, settings_path)` function to parser.lua
  - Read settings.local.json for hook registrations
  - Parse hooks section to extract event → hook mappings
  - Return structured event → hooks map
- [x] Add `get_extended_structure()` function to parser.lua
  - Call existing `get_command_structure()`
  - Call `scan_agents_directory()` for both global and local
  - Call `scan_hooks_directory()` for both global and local
  - Call `build_agent_dependencies()` and `build_hook_dependencies()`
  - Return unified structure with commands, agents, and hooks

Testing:
```bash
# Test in Neovim with :lua
:lua local parser = require('neotex.plugins.ai.claude.commands.parser')
:lua local structure = parser.get_extended_structure()
:lua vim.print(structure.agents)
:lua vim.print(structure.hooks)
:lua vim.print(structure.agent_dependencies)
:lua vim.print(structure.hook_events)
```

Expected outcomes:
- Agents parsed correctly with all metadata
- Hooks parsed correctly with event associations
- Agent dependencies mapped (orchestrate → 5 agents)
- Hook events mapped (Stop → 2 hooks, etc.)

### Phase 2: Picker Integration [COMPLETED]
**Objective**: Modify create_picker_entries() to include agents and hooks in hierarchy
**Complexity**: High

Tasks:
- [x] Update `show_commands_picker()` in picker.lua:835 to call `get_extended_structure()`
  - Replace `parser.get_command_structure()` call
  - Pass agents and hooks to `create_picker_entries()`
- [x] Modify `create_picker_entries(structure, agents, hooks)` in picker.lua:20
  - Accept agents and hooks parameters
  - Add helper function `get_agents_for_command(command_name, agent_deps)`
  - Add helper function `get_hooks_for_event(event_name, hook_events)`
- [x] Extend entry creation loop for commands
  - After adding dependent commands
  - Add agent entries for current command using `get_agents_for_command()`
  - Use same tree characters (├─, └─)
  - Set `entry_type = "agent"` and `parent = command_name`
- [x] Add hook event entries after all commands
  - Loop through hook events
  - Add individual hook entries with tree characters
  - Add hook event header entry
  - Set `entry_type = "hook"` or `entry_type = "hook_event"`
- [x] Add formatting functions
  - `format_agent(agent, indent_char)` → returns formatted display string
  - `format_hook(hook, indent_char)` → returns formatted display string
  - `format_hook_event(event_name)` → returns formatted header string
  - Include `[agent]` or event prefix in display

Testing:
```bash
# Launch picker and verify display
<leader>ac
# Verify:
# - Agents appear under commands (e.g., orchestrate should have 5 agents)
# - Hooks appear under events (e.g., Stop should have 2 hooks)
# - Tree characters correct (├─ for non-last, └─ for last)
# - * indicator shows for local agents/hooks
```

Expected outcomes:
- Picker displays commands, agents, and hooks in unified hierarchy
- Visual indentation correct with tree characters
- Local indicator (*) works for all types

### Phase 3: Previewer Enhancement
**Objective**: Enhance previewer to display agent and hook information
**Complexity**: Medium

Tasks:
- [ ] Update `create_command_previewer()` in picker.lua:106
  - Add case for `entry_type == "agent"` in define_preview
  - Display agent name, description, allowed tools, parent commands, filepath
  - Use markdown formatting
- [ ] Add hook preview case
  - Add case for `entry_type == "hook"` in define_preview
  - Display hook name, description, triggered events, script path
  - Use markdown formatting
- [ ] Add hook event preview case
  - Add case for `entry_type == "hook_event"` in define_preview
  - Display event name, description, when triggered, registered hooks
  - Use markdown formatting
- [ ] Add helper functions
  - `get_hook_event_description(event_name)` → returns description string
  - `get_hook_event_trigger_info(event_name)` → returns trigger timing info
  - Use lookup tables for event descriptions
- [ ] Update help text in preview (is_help case)
  - Add agent/hook navigation info
  - Update keyboard shortcuts description
  - Explain entry types and indicators
  - Update [Load All Commands] description

Testing:
```bash
# Launch picker and navigate through entries
<leader>ac
# Select agent entry → verify preview shows:
#   - Agent name and description
#   - Allowed tools
#   - Parent commands that use it
#   - File path
# Select hook entry → verify preview shows:
#   - Hook name and description
#   - Triggered events
#   - Script path
# Select hook event → verify preview shows:
#   - Event description
#   - Trigger timing
#   - Registered hooks
```

Expected outcomes:
- Agent preview displays all metadata
- Hook preview displays all metadata
- Hook event preview shows registered hooks
- Help text updated with new features

### Phase 4: File Management Functions
**Objective**: Implement load, update, save functions for agents and hooks
**Complexity**: Medium

Tasks:
- [ ] Implement `load_agent_locally(agent, silent)` in picker.lua
  - Similar to `load_command_locally()` (picker.lua:308)
  - Copy from `~/.config/.claude/agents/` to `.claude/agents/`
  - Check if already local, skip if so
  - Show notification unless silent
  - Return success boolean
- [ ] Implement `load_hook_locally(hook, silent)` in picker.lua
  - Similar to load_agent_locally but for hooks
  - Copy from `~/.config/.claude/hooks/` to `.claude/hooks/`
  - **Preserve executable permissions** (important for hooks)
  - Use vim.fn.getfperm() and vim.fn.setfperm() for permissions
  - Return success boolean
- [ ] Implement `update_agent_from_global(agent, silent)` in picker.lua
  - Similar to `update_command_from_global()` (picker.lua:575)
  - Overwrite local agent with global version
  - Show notification unless silent
  - Return success boolean
- [ ] Implement `update_hook_from_global(hook, silent)` in picker.lua
  - Similar to update_agent_from_global
  - **Preserve executable permissions** after overwrite
  - Return success boolean
- [ ] Implement `save_agent_to_global(agent, silent)` in picker.lua
  - Similar to `save_command_to_global()` (picker.lua:674)
  - Copy local agent to `~/.config/.claude/agents/`
  - Check if agent is local first
  - Show notification unless silent
  - Return success boolean
- [ ] Implement `save_hook_to_global(hook, silent)` in picker.lua
  - Similar to save_agent_to_global
  - **Preserve executable permissions** when copying
  - Return success boolean

Testing:
```lua
# Test in Neovim
:lua local picker = require('neotex.plugins.ai.claude.commands.picker')
# Create test agent/hook structures and test functions
# Verify:
# - Files copied correctly
# - Permissions preserved for hooks
# - Notifications shown
# - Error handling works
```

Expected outcomes:
- All file operations work correctly
- Executable permissions preserved for hooks
- Notifications show operation results
- Error handling robust

### Phase 5: Enhanced Load All Commands
**Objective**: Extend load_all_commands_locally() to handle agents and hooks
**Complexity**: Medium

Tasks:
- [ ] Rename `load_all_commands_locally()` to `load_all_globally()` in picker.lua:427
  - More accurate name for the operation
  - Update all references in the file
- [ ] Add helper function `scan_directory_for_sync(dir, extension)`
  - Scans directory for files with extension (.md or .sh)
  - Checks which are new vs existing locally
  - Returns {new_files=[], update_files=[], new_count=N, update_count=N}
- [ ] Add helper function `sync_files(file_list, global_dir, local_dir, preserve_perms)`
  - Copies new files
  - Replaces existing files
  - Preserves permissions if preserve_perms=true (for hooks)
  - Returns {total=N, new=N, updated=N}
- [ ] Update `load_all_globally()` function
  - Call `scan_directory_for_sync()` for commands, agents, hooks
  - Calculate total counts for confirmation dialog
  - Update confirmation message to show breakdown by type
  - Create local directories (.claude/agents/, .claude/hooks/) if needed
  - Call `sync_files()` for each type
  - Report results with counts per type
- [ ] Update preview for `is_load_all` entry
  - Show counts for commands, agents, and hooks
  - Display what will be copied vs replaced
  - Update description text

Testing:
```bash
# Launch picker and select [Load All Commands]
<leader>ac
# Select Load All entry → verify preview shows:
#   - Command counts (new and update)
#   - Agent counts (new and update)
#   - Hook counts (new and update)
# Press Enter → verify confirmation dialog shows counts
# Confirm → verify:
#   - All items synchronized
#   - Executable permissions preserved for hooks
#   - Notification shows counts
#   - Picker refreshes
```

Expected outcomes:
- Load All synchronizes all three types
- Confirmation dialog shows counts per type
- Executable permissions preserved
- Success notification with breakdown

### Phase 6: Action Mappings and Integration Testing
**Objective**: Update keyboard shortcuts and perform comprehensive testing
**Complexity**: Medium

Tasks:
- [ ] Update `actions.select_default` mapping in picker.lua:876
  - Add case for `entry_type == "agent"` → open agent file in buffer
  - Add case for `entry_type == "hook"` → open hook script in buffer
  - Add case for `entry_type == "hook_event"` → do nothing (header only)
  - Preserve existing command and Load All logic
- [ ] Update `<C-l>` (load locally) mapping in picker.lua:898
  - Add case for agents → call `load_agent_locally()`
  - Add case for hooks → call `load_hook_locally()`
  - Refresh picker after operation
  - Preserve existing command logic
- [ ] Update `<C-u>` (update from global) mapping in picker.lua:933
  - Add case for agents → call `update_agent_from_global()`
  - Add case for hooks → call `update_hook_from_global()`
  - Refresh picker after operation
  - Preserve existing command logic
- [ ] Update `<C-s>` (save to global) mapping in picker.lua:961
  - Add case for agents → call `save_agent_to_global()`
  - Add case for hooks → call `save_hook_to_global()`
  - Refresh picker after operation
  - Preserve existing command logic
- [ ] Add helper function `refresh_picker(opts, current_prompt)`
  - Closes current picker
  - Re-opens with same options
  - Restores search prompt if any
  - Used after all modify operations
- [ ] Comprehensive integration testing
  - Test all keyboard shortcuts with all entry types
  - Test picker refresh after operations
  - Test with local and global artifacts
  - Test permission preservation for hooks
  - Test error cases (missing files, permissions, etc.)
  - Verify no regressions in command functionality

Testing:
```bash
# Full integration test
<leader>ac

# Test agent operations
# Navigate to agent entry
# Press Enter → should open agent file
# Press Ctrl-l → should load locally (if global)
# Press Ctrl-u → should update from global
# Press Ctrl-s → should save to global (if local)

# Test hook operations
# Navigate to hook entry
# Press Enter → should open hook script
# Press Ctrl-l → should load locally with exec perms
# Press Ctrl-u → should update from global with exec perms
# Press Ctrl-s → should save to global with exec perms

# Test hook event
# Navigate to hook event header
# Press Enter → should do nothing
# Verify preview shows event info

# Test Load All
# Select [Load All Commands]
# Verify preview shows counts
# Press Enter → confirm dialog
# Verify all types synchronized

# Test existing commands
# Verify all command operations still work
# Verify Ctrl-n still creates new command
# Verify Ctrl-e still edits command
```

Expected outcomes:
- All keyboard shortcuts work for all entry types
- Picker refreshes correctly after operations
- Executable permissions preserved for hooks
- No regressions in command functionality
- Error handling robust for all operations

## Testing Strategy

### Unit Testing
- Parser functions tested independently
- File management functions tested with mock data
- Format functions tested for correct output

### Integration Testing
- Full picker workflow tested end-to-end
- All keyboard shortcuts tested with all entry types
- Load All tested with various scenarios
- Permission handling tested for hooks

### Regression Testing
- Verify all existing command functionality preserved
- Test backward compatibility with projects without agents/hooks
- Verify picker performance with large numbers of entries

### Test Cases
1. **Empty directories**: Project with no `.claude/agents/` or `.claude/hooks/`
2. **Global only**: Items only in `~/.config/.claude/`
3. **Local only**: Items only in project `.claude/`
4. **Mixed**: Some items global, some local, some both
5. **Permission scenarios**: Hook scripts with various permissions
6. **Large scale**: Many commands, agents, and hooks
7. **Error cases**: Missing files, read errors, write errors

## Documentation Requirements

### Code Documentation
- [ ] Add docstrings to all new parser functions
- [ ] Add docstrings to all new file management functions
- [ ] Add inline comments explaining complex logic
- [ ] Document data structures in comments

### User Documentation
- [ ] Update picker.lua module comments with new features
- [ ] Update help text in previewer with new shortcuts
- [ ] Document new entry types and indicators

### README Updates
- [ ] Update `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md`
  - Document agents and hooks support
  - Explain dependency tracking
  - Show example picker display
  - List all keyboard shortcuts

## Dependencies

### External Dependencies
- Existing parser.lua and picker.lua modules
- Telescope.nvim (already dependency)
- plenary.nvim (already dependency for parser)

### File Dependencies
- `.claude/agents/*.md` files with YAML frontmatter
- `.claude/hooks/*.sh` files with header comments
- `.claude/settings.local.json` for hook registrations
- Existing command files with `subagent_type:` references

### Standards Compliance
- Follow Lua code standards from nvim/CLAUDE.md
- 2 spaces indentation, expandtab
- snake_case for variables/functions
- pcall for error handling
- Comprehensive error messages

## Risk Assessment

### High Risk
- **Permission handling for hooks**: Must preserve executable permissions
  - Mitigation: Use vim.fn.getfperm/setfperm, test thoroughly
- **Parser complexity**: Three different parsing approaches (commands, agents, hooks)
  - Mitigation: Implement incrementally, test each type independently

### Medium Risk
- **Performance**: Large numbers of entries could slow picker
  - Mitigation: Profile with realistic data, optimize if needed
- **Backward compatibility**: Projects without agents/hooks
  - Mitigation: Graceful handling of missing directories

### Low Risk
- **UI complexity**: More entry types in hierarchy
  - Mitigation: Use consistent formatting, clear indicators
- **Code maintenance**: Larger codebase
  - Mitigation: Good documentation, clear separation of concerns

## Notes

### Design Decisions

**Entry Ordering**:
- Commands first (existing behavior)
- Hook events last (new section)
- Maintains visual separation

**Dependency Tracking**:
- Agents shown under ALL commands that use them (may appear multiple times)
- Hooks shown once under their event group
- Clear parent-child relationships

**Permission Handling**:
- Critical for hooks (must be executable)
- Use Vim's built-in file permission functions
- Test thoroughly on different systems

**Load All Behavior**:
- Replaces existing local items (not just new items)
- Preserves local-only items without global equivalents
- Single confirmation for all operations

### Implementation Timeline
Estimated 17-24 hours based on research report:
- Phase 1: 2-3 hours
- Phase 2: 3-4 hours
- Phase 3: 2-3 hours
- Phase 4: 3-4 hours
- Phase 5: 2-3 hours
- Phase 6: 3-4 hours
- Documentation: 2-3 hours

### Future Enhancements
- Create new agent command (similar to Ctrl-n for commands)
- Hook enablement toggle from picker
- Dependency visualization
- Search/filter by type
- Agent templates
