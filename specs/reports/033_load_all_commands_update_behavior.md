# Load All Commands Update Behavior Research Report

## Metadata
- **Date**: 2025-10-01
- **Scope**: Enhancement to `[Load All Commands]` feature in Claude commands picker to support updating existing local commands from global versions with user confirmation
- **Primary Directory**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/`
- **Files Analyzed**:
  - `picker.lua` (953 lines) - Main picker implementation
  - `README.md` - Documentation
- **Related Functions**:
  - `load_all_commands_locally()` - picker.lua:425
  - `update_command_from_global()` - picker.lua:488
  - `load_command_locally()` - picker.lua:308

## Executive Summary

The `[Load All Commands]` feature currently copies only global commands that don't already exist locally. The user wants this feature enhanced to act as a batch version of `<C-u>` (update command):

1. **Copy new commands**: Load global commands not yet present locally (existing behavior)
2. **Update matching commands**: Replace local commands that have the same name as global commands from `~/.config/.claude/commands/`
3. **Preserve unique local commands**: Leave untouched any local commands that don't exist in the global directory
4. **Simple confirmation**: Show a yes/no confirmation dialog before proceeding (no need to list individual commands)

This parallels the existing `<C-u>` (update command) functionality but applied in batch mode with a simple confirmation for safety.

## Current Implementation Analysis

### Existing Load All Behavior (picker.lua:425-482)

The `load_all_commands_locally()` function currently:

```lua
-- Load all primary commands and their dependencies
for name, data in pairs(structure.primary_commands) do
  if not data.command.is_local and data.command.filepath then
    local success = load_command_locally(data.command, true)  -- Silent mode for batch
    if success then
      loaded_count = loaded_count + 1
      table.insert(commands_loaded, name)
    end
  end
  -- Load dependent commands...
end
```

**Key Behavior**:
- Only processes commands where `is_local == false` (global commands not yet local)
- Uses `load_command_locally()` which **preserves existing local files** (picker.lua:340)
- No overwriting or updating of existing local commands
- No user confirmation required (safe operation)

### Existing Update Command Behavior (picker.lua:488-581)

The `update_command_from_global()` function provides the update logic:

```lua
-- Find the global version of the command
local global_commands_dir = global_dir .. "/.claude/commands"
local global_filepath = global_commands_dir .. "/" .. command.name .. ".md"

-- Check if global version exists
if vim.fn.filereadable(global_filepath) ~= 1 then
  -- Error handling
  return false
end

-- Copy the global file to local (overwriting if exists)
local local_filepath = local_commands_dir .. "/" .. command.name .. ".md"
local content = table.concat(vim.fn.readfile(global_filepath), "\n")
vim.fn.writefile(vim.split(content, "\n"), local_filepath)
```

**Key Behavior**:
- Finds global version of command by name
- **Overwrites local version** without checking for differences
- Works on single commands (called via `<C-u>` keybinding)
- Also updates dependent commands recursively
- No user confirmation (assumes user intent via explicit keybinding)

### Load Command Locally Behavior (picker.lua:308-421)

The `load_command_locally()` function:

```lua
-- If command is already local or we're in .config directory, nothing to do
if command.is_local or project_dir == global_dir then
  if not silent then
    notify.editor(
      string.format("Command '%s' is already local", command.name),
      notify.categories.STATUS,
      { command = command.name }
    )
  end
  return true
end
```

**Key Behavior**:
- **Skips if command is already local** (picker.lua:340-348)
- Only copies when local version doesn't exist
- Recursively loads dependencies
- Safe operation (no overwrites)

## Gap Analysis

### What's Missing

1. **Batch Update**: No batch version of `update_command_from_global()`
2. **User Confirmation**: No simple yes/no confirmation before batch operation
3. **Mixed Operation**: No single operation that both loads new and updates existing commands

### Current Workarounds

Users must manually:
1. Select each command individually
2. Press `<C-u>` to update from global
3. Repeat for every command needing update

This is tedious when multiple commands need updating after global command changes.

### User Requirements Clarification

**Acceptable behavior for `<C-u>`**: Overwrites local version without checking differences or asking confirmation
**Desired behavior for `[Load All Commands]`**: Batch version of `<C-u>` with simple yes/no confirmation
**Critical requirement**: Local commands that don't exist in `~/.config/.claude/commands/` must remain unchanged

## Technical Requirements

### 1. Identify Commands for Batch Operation

The operation needs to process all global commands and categorize them:

1. **New commands**: Global commands not present locally (copy to local)
2. **Existing commands**: Global commands that exist locally (replace local with global)
3. **Local-only commands**: Local commands without global equivalents (DO NOT TOUCH)

**Simplified Approach** (no content comparison needed):
```lua
local commands_to_load = {}    -- New commands to copy
local commands_to_update = {}  -- Existing commands to replace

-- Scan all global commands
for name, data in pairs(structure.primary_commands) do
  if not data.command.is_local then
    -- Global command - will be loaded
    table.insert(commands_to_load, data.command)
  end
end

-- Scan for local commands that have global versions (need updating)
for name, data in pairs(structure.primary_commands) do
  if data.command.is_local then
    local global_path = global_dir .. "/.claude/commands/" .. name .. ".md"
    if vim.fn.filereadable(global_path) == 1 then
      -- Local command has global version - will be replaced
      table.insert(commands_to_update, data.command)
    end
    -- If no global version exists, command is untouched (local-only)
  end
end
```

**Key Logic**: Only check if global version *exists*, not if content differs. This matches `<C-u>` behavior.

### 2. Simple User Confirmation

**Required**: Simple yes/no confirmation dialog before batch operation

**Information to Display**:
- Total number of commands that will be loaded/updated
- Simple warning message
- Yes/No options

**Implementation** (Simple Vim Confirm Dialog):
```lua
-- Count operations
local total_new = #commands_to_load
local total_update = #commands_to_update
local total_operations = total_new + total_update

-- Skip confirmation if no operations needed
if total_operations == 0 then
  notify.editor("All commands already in sync", notify.categories.STATUS)
  return 0
end

-- Show simple confirmation
local message = string.format(
  "Load all commands from global directory?\n\n" ..
  "This will:\n" ..
  "  - Copy %d new commands\n" ..
  "  - Replace %d existing local commands\n\n" ..
  "Local-only commands will not be affected.",
  total_new,
  total_update
)

local choice = vim.fn.confirm(message, "&Yes\n&No", 2)  -- Default to No

if choice ~= 1 then
  notify.editor("Load all commands cancelled", notify.categories.STATUS)
  return 0
end

-- Proceed with batch operation
```

**Key Features**:
- No command listing (user doesn't need to see which specific commands)
- Clear counts of operations
- Default to "No" for safety
- Simple, concise message

### 3. Batch Update Implementation

Complete rewrite of `load_all_commands_locally()` function:

```lua
local function load_all_commands_locally()
  local notify = require('neotex.util.notifications')
  local parser = require('neotex.plugins.ai.claude.commands.parser')

  local project_dir = vim.fn.getcwd()
  local global_dir = vim.fn.expand("~/.config")

  -- Don't load if we're in the global directory
  if project_dir == global_dir then
    notify.editor("Already in the global commands directory", notify.categories.STATUS)
    return 0
  end

  -- Get current command structure
  local structure = parser.get_command_structure()
  local global_commands_dir = global_dir .. "/.claude/commands"

  -- Categorize all global commands
  local commands_to_load = {}    -- New commands (not yet local)
  local commands_to_update = {}  -- Existing local commands with global versions

  -- Scan all global commands from ~/.config/.claude/commands/
  local global_files = vim.fn.glob(global_commands_dir .. "/*.md", false, true)

  for _, global_path in ipairs(global_files) do
    local command_name = vim.fn.fnamemodify(global_path, ":t:r")  -- filename without .md
    local local_path = project_dir .. "/.claude/commands/" .. command_name .. ".md"

    if vim.fn.filereadable(local_path) == 1 then
      -- Local version exists - will be replaced
      table.insert(commands_to_update, {
        name = command_name,
        global_path = global_path,
        local_path = local_path
      })
    else
      -- No local version - will be copied
      table.insert(commands_to_load, {
        name = command_name,
        global_path = global_path,
        local_path = local_path
      })
    end
  end

  -- Show confirmation
  local total_operations = #commands_to_load + #commands_to_update
  if total_operations == 0 then
    notify.editor("All commands already in sync", notify.categories.STATUS)
    return 0
  end

  local message = string.format(
    "Load all commands from global directory?\n\n" ..
    "This will:\n" ..
    "  - Copy %d new commands\n" ..
    "  - Replace %d existing local commands\n\n" ..
    "Local-only commands will not be affected.",
    #commands_to_load,
    #commands_to_update
  )

  local choice = vim.fn.confirm(message, "&Yes\n&No", 2)
  if choice ~= 1 then
    notify.editor("Load all commands cancelled", notify.categories.STATUS)
    return 0
  end

  -- Create local commands directory if needed
  local local_commands_dir = project_dir .. "/.claude/commands"
  vim.fn.mkdir(local_commands_dir, "p")

  -- Copy new commands
  local loaded_count = 0
  for _, cmd in ipairs(commands_to_load) do
    local content = table.concat(vim.fn.readfile(cmd.global_path), "\n")
    vim.fn.writefile(vim.split(content, "\n"), cmd.local_path)
    loaded_count = loaded_count + 1
  end

  -- Replace existing commands
  local updated_count = 0
  for _, cmd in ipairs(commands_to_update) do
    local content = table.concat(vim.fn.readfile(cmd.global_path), "\n")
    vim.fn.writefile(vim.split(content, "\n"), cmd.local_path)
    updated_count = updated_count + 1
  end

  -- Report results
  notify.editor(
    string.format("Loaded %d new, replaced %d existing commands", loaded_count, updated_count),
    notify.categories.SUCCESS
  )

  return loaded_count + updated_count
end
```

**Key Changes**:
- Scans global directory directly (not dependent on parser's is_local flag)
- No content comparison (just checks existence)
- Simple yes/no confirmation with counts
- Both loads and updates in single operation
- Local-only commands are never touched

## Recommended Implementation Strategy

### Phase 1: Core Implementation
1. Rewrite `load_all_commands_locally()` function with direct global directory scanning
2. Implement simple yes/no confirmation dialog
3. Handle both new commands (copy) and existing commands (replace) in single operation
4. Update success notification to show both counts

### Phase 2: Preview Pane Enhancement (Optional)
1. Update preview pane for `[Load All Commands]` entry to show counts
2. Display: "Copy X new commands, Replace Y existing commands"
3. Clarify that local-only commands won't be affected

### Phase 3: Testing
1. Test with only new commands (no local versions)
2. Test with only updates (all commands exist locally)
3. Test with mixed scenario (some new, some existing)
4. Test with local-only commands (verify they remain unchanged)
5. Test confirmation cancellation
6. Test with empty global directory
7. Verify picker refresh shows updated `*` markers

### Phase 4: Documentation Update
1. Update README.md to reflect new batch update behavior
2. Document that local-only commands are preserved
3. Update keyboard shortcuts help in picker

## Alternative Approaches Considered (Not Recommended)

### Option A: Separate "Update All" Entry
Add a new picker entry `[Update All Commands]` separate from `[Load All Commands]`:
- `[Load All Commands]` - Only copies new commands (current behavior)
- `[Update All Commands]` - Only updates existing local commands from global

**Why Rejected**: User wants single unified operation (batch version of `<C-u>`), not two separate operations

### Option B: Content Comparison Before Update
Only update local commands if content differs from global version:
```lua
if local_content ~= global_content then
  -- Update only if different
end
```

**Why Rejected**: User explicitly wants behavior matching `<C-u>` which overwrites without checking differences

### Option C: List Commands in Confirmation Dialog
Show list of commands that will be replaced in confirmation dialog.

**Why Rejected**: User explicitly requested simple yes/no confirmation without command listing

## Risks and Considerations

### Data Loss Risk
**Risk**: Users lose local customizations when commands are replaced
**Mitigation**:
- Clear confirmation message explaining operations
- Default to "No" in confirmation dialog
- Message explicitly states "Local-only commands will not be affected"
- This matches `<C-u>` behavior which user finds acceptable

### Local-Only Commands Must Be Preserved
**Critical Requirement**: Commands in `.claude/commands/` without global equivalents must remain unchanged

**Implementation Check**:
```lua
-- Only process global commands
local global_files = vim.fn.glob(global_commands_dir .. "/*.md", false, true)

for _, global_path in ipairs(global_files) do
  -- Only touches commands that exist in global directory
  -- Local-only commands are never in this loop
end
```

**Verification**: Local commands without global versions are never scanned or touched

### Performance
**Risk**: Reading many files could be slow
**Mitigation**:
- No content comparison (just existence check)
- File operations only after user confirms
- Typical command files are < 1KB
- Operation only runs when user selects `[Load All Commands]`

### User Experience
**Risk**: Confirmation dialog may be annoying for users who know what they want
**Mitigation**:
- Single simple dialog (not multiple dialogs)
- Clear counts so user knows exactly what will happen
- Can press 'N' to cancel quickly if needed
- Only shows when operations are needed (skips if already in sync)

## Implementation Checklist

### Core Changes
- [ ] Rewrite `load_all_commands_locally()` function in picker.lua
  - [ ] Scan global directory directly with `vim.fn.glob()`
  - [ ] Categorize into commands_to_load (new) and commands_to_update (existing)
  - [ ] Implement simple yes/no confirmation dialog
  - [ ] Copy new commands
  - [ ] Replace existing commands
  - [ ] Update success notification with both counts

### Preview Pane Update (Optional)
- [ ] Update preview for `[Load All Commands]` entry (picker.lua:150-208)
  - [ ] Show counts of new vs existing commands
  - [ ] Clarify local-only commands won't be affected

### Testing Scenarios
- [ ] Test: Only new commands (no local versions exist)
- [ ] Test: Only updates (all commands already exist locally)
- [ ] Test: Mixed scenario (some new, some existing)
- [ ] Test: Local-only commands remain unchanged
- [ ] Test: User cancels confirmation dialog
- [ ] Test: Empty global directory (no commands to load)
- [ ] Test: Empty local directory (all commands are new)
- [ ] Test: Picker refresh shows updated `*` markers after operation

### Documentation
- [ ] Update README.md (commands/README.md)
  - [ ] Update "Batch Loading" section (lines 113-120)
  - [ ] Document new update behavior
  - [ ] Clarify local-only command preservation
- [ ] Update keyboard shortcuts help in picker preview
  - [ ] Update help text for `[Load All Commands]` entry

### Error Handling
- [ ] Handle file read errors gracefully
- [ ] Handle file write permission errors
- [ ] Handle case where global directory doesn't exist
- [ ] Verify directory creation succeeds

## References

### Key Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
  - `load_all_commands_locally()` - Line 425
  - `update_command_from_global()` - Line 488
  - `load_command_locally()` - Line 308
  - Preview pane logic - Lines 150-208

### Related Documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md`
  - "Load All Commands" section - Lines 113-120
  - "Updating Commands" section - Lines 93-100

### Similar Patterns
- Individual command update via `<C-u>` keybinding (picker.lua:845-871)
- Batch loading of dependencies (picker.lua:383-418)
- Save to global with `<C-s>` (picker.lua:587-692)

## Summary of User Requirements

Based on user feedback, the implementation must:

1. **No Content Comparison**: Don't check if files differ - just replace if global version exists (matches `<C-u>` behavior)
2. **Simple Confirmation**: Single yes/no dialog showing counts, no command listing needed
3. **Preserve Local-Only**: Critical - commands in local directory without global equivalents must never be touched
4. **Batch Operation**: Single operation that both loads new and replaces existing commands
5. **Default to No**: Confirmation dialog defaults to "No" for safety

## Next Steps

1. **Create Implementation Plan**: Use `/plan` based on this research
2. **Implement Core Function**: Rewrite `load_all_commands_locally()` as specified
3. **Test Thoroughly**: Especially verify local-only commands are preserved
4. **Update Documentation**: README.md and help text

---

**Report Status**: Complete - Revised based on user clarification
**Recommended Action**: Create implementation plan with `/plan` command
