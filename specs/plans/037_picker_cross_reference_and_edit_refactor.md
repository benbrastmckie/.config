# Claude Command Picker Cross-Reference and Edit Refactor

## Metadata
- **Date**: 2025-10-08
- **Feature**: Picker agent/command cross-referencing and universal file editing
- **Scope**: Refactor picker.lua to show agent→command relationships, extend file editing to all artifact types, and implement context-aware Return key behavior
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: None

## Overview

The Claude command picker currently has three main limitations:

1. **Incomplete Cross-Referencing**: While the picker shows "Agents used by this command" under command previews, it doesn't show "Commands that use this agent" under agent previews. The infrastructure exists (parser.lua builds `agent.parent_commands` arrays), but the picker doesn't display this information.

2. **Limited File Editing**: The `<C-e>` key only supports editing Commands and Hook Events. Other artifact types (Docs, Lib, Templates, TTS Files) cannot be edited via the picker, despite having `filepath` properties.

3. **Non-Context-Aware Return Key**: The Return key only inserts commands into Claude Code. For file artifacts (Docs, Lib, Templates, Hooks, TTS), it would be more useful to open them for editing rather than attempting insertion.

This refactor will:
- Display "Commands that use this agent" in agent previews by accessing existing `agent.parent_commands` data
- Extend `<C-e>` file editing to all artifact types with file paths
- Make Return key context-aware: insert Commands/Agents, but open files for non-insertable artifacts

## Success Criteria
- [ ] Agent previews show "Commands that use this agent" section with clickable command names
- [ ] `<C-e>` opens files for editing for all artifact types (Commands, Agents, Hooks, Docs, Lib, Templates, TTS)
- [ ] Return key inserts Commands and Agents into Claude Code (existing behavior preserved)
- [ ] Return key opens files for editing for Docs, Lib, Templates, Hooks, and TTS Files
- [ ] All existing `<C-l>` (load local), `<C-u>` (load global), `<C-s>` (show source) functionality preserved
- [ ] No regressions in existing picker behavior
- [ ] Code follows Neovim configuration guidelines (nvim/CLAUDE.md)

## Technical Design

### 1. Agent Preview Cross-Referencing

**Current State**:
- `parser.lua:483-527` - `build_agent_dependencies()` already populates `agent.parent_commands` arrays
- `picker.lua:1008-1029` - Agent preview shows `entry.value.parent` (only works for agents nested under commands)
- Standalone agents in [Agents] section have no parent display

**Design**:
- Access `agent.parent_commands` array in agent preview generation
- Display "Commands that use this agent:" section similar to how commands display their agents
- Format as clickable list using the same tree characters (├─, └─)
- Handle case where `parent_commands` is empty or nil

**Implementation Location**: `picker.lua` preview generation for agents (around line 1019)

### 2. Universal File Editing

**Current State**:
- `picker.lua:2742-2760` - `<C-e>` handler only supports Commands and Hook Events
- Commands use `edit_command_file()` with special local/global logic
- Hook Events use simple `vim.cmd("edit")` with first hook file

**Design**:
- Add `elseif` branches for `entry_type` values: "agent", "template", "lib", "doc", "tts_file"
- Create simple `edit_file()` helper that opens files with proper escaping
- No special local/global logic needed for non-command artifacts (they already have correct filepath)
- Preserve existing Command and Hook editing behavior

**Implementation Location**: `picker.lua:2742-2760` (extend existing `<C-e>` handler)

### 3. Context-Aware Return Key

**Current State**:
- `picker.lua:2672-2696` - Return key only handles Commands (inserts via `send_command_to_terminal()`)
- No action for Agents (they're nested under commands, not standalone)
- No action for file artifacts (Docs, Lib, Templates, Hooks, TTS)

**Design**:
- **Insertable artifacts** (Commands): Keep existing `send_command_to_terminal()` behavior
- **Editable artifacts** (Docs, Lib, Templates, Hooks, TTS): Open file for editing
- **Agent artifacts**: Insert agent reference into Claude Code using `@agent_name` syntax
- Decision logic based on `entry_type` field

**Implementation Location**: `picker.lua:2672-2696` (extend existing Return key handler)

### 4. Data Structures

All required data already exists:
- `agent.parent_commands` - Array of command names that use this agent (populated by parser)
- `entry.value.filepath` - File path for all artifact types
- `entry.value.entry_type` - Artifact type discriminator
- `entry.value.is_local` - Local vs global indicator

No schema changes needed.

## Implementation Phases

### Phase 1: Add Agent Cross-Reference Display [COMPLETED]
**Objective**: Show "Commands that use this agent" in agent previews
**Complexity**: Low

Tasks:
- [x] Read current agent preview generation code in picker.lua (around line 1008-1029)
- [x] Add logic to check if `agent.parent_commands` exists and is non-empty
- [x] Format "Commands that use this agent:" section header
- [x] Iterate over `parent_commands` array and format each command name with tree characters
- [x] Use same formatting style as "Agents used by this command" (├─, └─ for tree structure)
- [x] Handle edge cases: empty array, nil value, single command vs multiple commands
- [x] Test with agents that have 0, 1, and multiple parent commands

Testing:
```bash
# Open picker and navigate to [Agents] section
# Select standalone agents and verify preview shows parent commands
# Verify agents with no parents show appropriate message or omit section
# Verify agents under [Commands] still show parent info correctly
```

### Phase 2: Extend File Editing to All Artifact Types [COMPLETED]
**Objective**: Make `<C-e>` work for all artifacts with file paths
**Complexity**: Low

Tasks:
- [x] Read current `<C-e>` handler in picker.lua (lines 2742-2760)
- [x] Create simple `edit_file(filepath)` helper function that opens files with proper escaping
- [x] Add `elseif entry_type == "agent"` branch that calls `edit_file(selection.value.filepath)`
- [x] Add `elseif entry_type == "template"` branch with same logic
- [x] Add `elseif entry_type == "lib"` branch with same logic
- [x] Add `elseif entry_type == "doc"` branch with same logic
- [x] Add `elseif entry_type == "tts_file"` branch with same logic
- [x] Preserve existing Command editing logic (uses `edit_command_file()`)
- [x] Preserve existing Hook Event editing logic
- [x] Test editing each artifact type from picker

Testing:
```bash
# Open picker and navigate to each section: [Agents], [Templates], [Lib], [Docs], [TTS Files]
# Press <C-e> on items from each section
# Verify file opens correctly in editor
# Verify Commands and Hooks still use existing edit logic
# Test both local and global artifacts
```

### Phase 3: Implement Context-Aware Return Key [COMPLETED]
**Objective**: Return key inserts Commands/Agents but opens files for other artifacts
**Complexity**: Medium

Tasks:
- [x] Read current Return key handler in picker.lua (lines 2672-2696)
- [x] Add conditional logic based on `entry_type`
- [x] For `entry_type == "command"`: Keep existing `send_command_to_terminal()` behavior
- [x] For `entry_type == "agent"`: Insert `@agent_name` into Claude Code using same terminal insertion
- [x] For `entry_type` in {"doc", "lib", "template", "hook_event", "tts_file"}: Call `edit_file()` and close picker
- [x] Ensure picker closes after file editing action
- [x] Ensure picker stays open or closes appropriately after insertion action (check existing behavior)
- [x] Test each artifact type's Return key behavior

Testing:
```bash
# Open picker, press Return on a Command
# Verify command inserted into Claude Code terminal (existing behavior)

# Press Return on an Agent
# Verify @agent_name inserted into Claude Code

# Press Return on items from [Docs], [Lib], [Templates], [Hook Events], [TTS Files]
# Verify files open for editing (not inserted)
# Verify picker closes after opening file
```

### Phase 4: Integration Testing and Edge Cases [COMPLETED]
**Objective**: Comprehensive testing and edge case handling
**Complexity**: Low

Tasks:
- [x] Test agent cross-references with nested agents (agents displayed under commands)
- [x] Test agent cross-references with standalone agents
- [x] Test agents with no parent commands (should handle gracefully)
- [x] Test all file editing paths with both local (*) and global artifacts
- [x] Test Return key with all artifact types in sequence
- [x] Verify `<C-l>` (load local) still works for all types
- [x] Verify `<C-u>` (load global) still works for all types
- [x] Verify `<C-s>` (show source) still works for all types
- [x] Test with malformed file paths (ensure proper escaping)
- [x] Verify no regressions in existing picker functionality (search, filtering, help section)

Testing:
```bash
# Comprehensive picker workflow testing
# Open picker multiple times and test each operation
# Verify all keybindings documented in help section still work
# Test edge cases: empty directories, missing files, etc.
```

## Testing Strategy

### Manual Testing
All phases require manual testing via Neovim:
1. Open picker with appropriate keymap (e.g., `<leader>cc`)
2. Navigate through each section: [Commands], [Agents], [Templates], [Docs], [Lib], [Hook Events], [TTS Files]
3. Test each keybinding: Return, `<C-e>`, `<C-l>`, `<C-u>`, `<C-s>`
4. Verify preview content accuracy
5. Verify file editing opens correct files
6. Verify command/agent insertion works correctly

### Test Cases
- Agent with 0 parent commands (new agent not used by any command)
- Agent with 1 parent command
- Agent with multiple parent commands
- Agent nested under command (existing behavior)
- Each artifact type: Command, Agent, Template, Doc, Lib, Hook Event, TTS File
- Local (*) and global variants of each artifact
- Return key on each artifact type
- `<C-e>` on each artifact type
- Edge cases: missing files, invalid paths

### Regression Testing
Ensure existing functionality preserved:
- Command hierarchies (primary, dependent, workflow, utility)
- Agent nesting under commands
- Help section display
- Search/filtering functionality
- All existing keybindings

## Documentation Requirements

### Files to Update
- `nvim/lua/neotex/plugins/ai/claude/commands/README.md` - Document new picker capabilities
- `nvim/lua/neotex/plugins/ai/claude/README.md` - Update picker behavior description
- Inline code comments in `picker.lua` - Document new functions and logic

### Documentation Content
- Describe agent cross-reference display in previews
- Explain `<C-e>` now works for all artifact types
- Clarify Return key context-aware behavior (insert vs edit)
- Update keymap reference table if needed

## Dependencies

### Existing Code Dependencies
- `neotex.plugins.ai.claude.commands.parser` - Already provides `agent.parent_commands` data
- Telescope.nvim - Picker framework (no changes needed)
- Existing picker infrastructure - All data structures already in place

### No External Dependencies
All functionality uses existing infrastructure. No new dependencies required.

## Notes

### Design Decisions

1. **No Schema Changes**: All required data (`agent.parent_commands`, `filepath`, `entry_type`) already exists in the current implementation. This refactor only surfaces existing data.

2. **Preserve Existing Behavior**: All current keybindings and behaviors remain unchanged except where explicitly extended:
   - Commands: Existing edit and insert behavior unchanged
   - Hooks: Existing edit behavior unchanged
   - New: Agents, Docs, Lib, Templates, TTS gain edit capability
   - New: File artifacts gain Return key editing behavior

3. **Consistency**: Agent cross-reference display will mirror the existing "Agents used by this command" format for consistency.

4. **Context-Aware Actions**: Return key behavior varies by artifact type, which is intuitive:
   - Insertable items (Commands, Agents) → Insert into Claude Code
   - File items (Docs, Lib, Templates, Hooks, TTS) → Open for editing

### Implementation Simplicity

This refactor is simpler than it appears because:
- Parser already builds all cross-reference data
- All artifacts already have filepath information
- Entry type discriminator already exists
- Only need to surface existing data and route actions appropriately

### Future Enhancements

Potential future improvements (out of scope):
- Click-through from agent preview to parent command (jump to command in picker)
- Reverse: click from command's agent list to agent detail
- Batch operations on multiple artifacts
- Custom edit actions per artifact type
