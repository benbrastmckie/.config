# Project-Specific TTS Toggle Implementation Plan

## Metadata
- **Date**: 2025-10-03
- **Feature**: Make `<leader>at` toggle project-specific TTS configuration
- **Scope**: Modify TTS toggle keymap in which-key.lua to support project-local config
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Related Plans**: /home/benjamin/.config/nvim/specs/plans/027_fix_tts_toggle_directory_dependency.md
- **Implementation Summary**: /home/benjamin/.config/nvim/specs/summaries/028_implementation_summary.md
- **Workflow Summary**: /home/benjamin/.config/nvim/specs/summaries/028_project_specific_tts_toggle_workflow.md

## Overview

The `<leader>at` keymap currently toggles TTS in the global configuration file at `~/.config/.claude/tts/tts-config.sh`. This plan modifies it to toggle the project-specific configuration file at `.claude/tts/tts-config.sh` (relative to project root) instead. When the project-specific file doesn't exist, show a user-friendly notification following NOTIFICATIONS.md protocols.

### Current Behavior
- Toggles `TTS_ENABLED` in `~/.config/.claude/tts/tts-config.sh` (global config)
- Works from any directory (fixed in plan 027)
- Shows notifications for success/error states

### Desired Behavior
- Toggles `TTS_ENABLED` in `.claude/tts/tts-config.sh` (project-local config)
- Falls back to global config if project-specific doesn't exist
- Shows proper notification inviting user to create project config via `<leader>ac`
- Maintains existing error handling patterns

## Success Criteria
- [ ] `<leader>at` toggles TTS in project-specific config when it exists
- [ ] `<leader>at` falls back to global config when project-specific doesn't exist
- [ ] Notification appears using `neotex.util.notifications` module
- [ ] Notification follows NOTIFICATIONS.md protocols (ERROR category, plain text keybinding)
- [ ] File `.claude/tts/tts-config.sh` is modified correctly in project root
- [ ] Works consistently across different projects and directories

## Technical Design

### Project Root Detection

Use `vim.fn.getcwd()` for project root detection, consistent with existing codebase patterns:
- `neotex.plugins.ui.bufferline` uses `vim.fn.getcwd()` for session naming
- `neotex.plugins.ai.claude.core.worktree` uses `vim.fn.getcwd()` for worktree detection
- `neotex.plugins.ai.claude.commands.parser` uses `vim.fn.getcwd()` for context

Alternative considered: `git rev-parse --show-toplevel` for git-aware projects
**Decision**: Use `vim.fn.getcwd()` for consistency and simplicity

### Path Resolution Logic

```
Priority order:
1. {project_root}/.claude/tts/tts-config.sh (project-specific)
2. ~/.config/.claude/tts/tts-config.sh (global fallback)
```

Implementation approach:
```lua
local project_root = vim.fn.getcwd()
local project_config = project_root .. "/.claude/tts/tts-config.sh"
local global_config = vim.fn.expand('$HOME') .. "/.config/.claude/tts/tts-config.sh"

local config_path
if vim.fn.filereadable(project_config) == 1 then
  config_path = project_config
elseif vim.fn.filereadable(global_config) == 1 then
  config_path = global_config
else
  -- Show notification about missing config
  notify.editor(
    "No TTS config found. Use <leader>ac to create project-specific config.",
    notify.categories.ERROR,
    { project_root = project_root }
  )
  return
end
```

### Notification Integration

Use the unified notification system from `neotex.util.notifications`:

```lua
local notify = require('neotex.util.notifications')

-- File not found notification
notify.editor(
  "No TTS config found. Use <leader>ac to create project-specific config.",
  notify.categories.ERROR,
  { project_root = vim.fn.getcwd() }
)

-- Success notifications
notify.editor(
  "TTS enabled (project-specific)",
  notify.categories.USER_ACTION,
  { config_path = project_config }
)

notify.editor(
  "TTS disabled (global fallback)",
  notify.categories.USER_ACTION,
  { config_path = global_config }
)
```

Key points from NOTIFICATIONS.md:
- Use `notify.editor()` for editor feature operations
- Use `notify.categories.ERROR` for file-not-found (always shown)
- Use `notify.categories.USER_ACTION` for successful toggle (always shown)
- Keybindings in plain text: "Use <leader>ac to create it"
- Provide context for debugging (project_root, config_path)

### Code Structure

Extract toggle logic to a helper function for clarity:

```lua
local function toggle_tts_config(config_path, is_project_specific)
  -- Read, modify, write logic (reuse existing code)
  -- Return: success, message, error
end

-- In keymap definition
{ "<leader>at", function()
  local project_root = vim.fn.getcwd()
  local project_config = project_root .. "/.claude/tts/tts-config.sh"
  local global_config = vim.fn.expand('$HOME') .. "/.config/.claude/tts/tts-config.sh"

  local config_path, is_project_specific
  if vim.fn.filereadable(project_config) == 1 then
    config_path = project_config
    is_project_specific = true
  elseif vim.fn.filereadable(global_config) == 1 then
    config_path = global_config
    is_project_specific = false
  else
    notify.editor(
      "No TTS config found. Use <leader>ac to create project-specific config.",
      notify.categories.ERROR,
      { project_root = project_root }
    )
    return
  end

  local success, message, error = toggle_tts_config(config_path, is_project_specific)
  if success then
    local scope = is_project_specific and "(project)" or "(global)"
    notify.editor(message .. " " .. scope, notify.categories.USER_ACTION, {
      config_path = config_path
    })
  else
    notify.editor("Failed to toggle TTS: " .. error, notify.categories.ERROR, {
      config_path = config_path
    })
  end
end, desc = "toggle tts", icon = "󰔊" }
```

## Implementation Phases

### Phase 1: Add Notification Integration [COMPLETED]
**Objective**: Import notification module and prepare infrastructure
**Complexity**: Low

Tasks:
- [x] Add notification module import at top of which-key.lua
- [x] Verify notification module is available
- [x] Test basic notification calls work correctly
- [x] Document notification categories being used

Implementation:
```lua
-- At top of which-key.lua (near other requires)
local notify = require('neotex.util.notifications')
```

Testing:
```lua
-- Test notification manually in Neovim
:lua require('neotex.util.notifications').editor("Test notification", require('neotex.util.notifications').categories.USER_ACTION)
```

Expected Outcome:
- Notification module loaded successfully
- Test notifications appear correctly
- No errors in `:messages`

### Phase 2: Extract and Enhance Toggle Logic [COMPLETED]
**Objective**: Refactor existing toggle code into reusable helper function
**Complexity**: Medium

Tasks:
- [x] Create `toggle_tts_config(config_path, is_project_specific)` helper function
- [x] Move file read/write logic from keymap into helper
- [x] Keep existing error handling with `pcall()`
- [x] Return structured result: `success, message, error`
- [x] Add parameter to indicate project-specific vs global
- [x] Update success message to include scope indicator

Implementation:
```lua
-- Helper function defined before keymap definitions
local function toggle_tts_config(config_path, is_project_specific)
  -- Validate file exists (redundant check, but safe)
  if vim.fn.filereadable(config_path) ~= 1 then
    return false, nil, "Config file not readable: " .. config_path
  end

  -- Read file with error handling
  local ok, lines = pcall(vim.fn.readfile, config_path)
  if not ok then
    return false, nil, "Failed to read config: " .. tostring(lines)
  end

  -- Find and toggle TTS_ENABLED
  local modified = false
  local message
  for i, line in ipairs(lines) do
    if line:match("^TTS_ENABLED=") then
      if line:match("=true$") then
        lines[i] = "TTS_ENABLED=false"
        message = "TTS disabled"
      else
        lines[i] = "TTS_ENABLED=true"
        message = "TTS enabled"
      end
      modified = true
      break
    end
  end

  if not modified then
    return false, nil, "TTS_ENABLED not found in config file"
  end

  -- Write file with error handling
  local write_ok, write_err = pcall(vim.fn.writefile, lines, config_path)
  if not write_ok then
    return false, nil, "Failed to write config: " .. tostring(write_err)
  end

  return true, message, nil
end
```

Testing:
```bash
# Test extracted function manually
:lua local f = function(path, is_proj) ... end; print(vim.inspect(f("~/.config/.claude/tts/tts-config.sh", false)))
```

Expected Outcome:
- Helper function works independently
- Existing toggle functionality preserved
- Clear success/error return values
- Code is more maintainable

### Phase 3: Implement Project-Specific Path Resolution [COMPLETED]
**Objective**: Add project root detection and path priority logic
**Complexity**: Medium

Tasks:
- [x] Add project root detection using `vim.fn.getcwd()`
- [x] Implement path resolution with priority order
- [x] Check project-specific config first, then global
- [x] Show notification when no config found
- [x] Add scope indicator to success message (project/global)
- [x] Update keymap function to use new logic
- [x] Replace existing toggle in which-key.lua (lines 215-264)

Implementation:
```lua
{ "<leader>at", function()
  local notify = require('neotex.util.notifications')

  -- Detect project root and construct paths
  local project_root = vim.fn.getcwd()
  local project_config = project_root .. "/.claude/tts/tts-config.sh"
  local global_config = vim.fn.expand('$HOME') .. "/.config/.claude/tts/tts-config.sh"

  -- Resolve config path with priority
  local config_path, is_project_specific
  if vim.fn.filereadable(project_config) == 1 then
    config_path = project_config
    is_project_specific = true
  elseif vim.fn.filereadable(global_config) == 1 then
    config_path = global_config
    is_project_specific = false
  else
    notify.editor(
      "No TTS config found. Use <leader>ac to create project-specific config.",
      notify.categories.ERROR,
      { project_root = project_root }
    )
    return
  end

  -- Toggle config using helper
  local success, message, error = toggle_tts_config(config_path, is_project_specific)

  if success then
    local scope = is_project_specific and "(project)" or "(global)"
    notify.editor(
      message .. " " .. scope,
      notify.categories.USER_ACTION,
      { config_path = config_path }
    )
  else
    notify.editor(
      "Failed to toggle TTS: " .. error,
      notify.categories.ERROR,
      { config_path = config_path }
    )
  end
end, desc = "toggle tts", icon = "󰔊" },
```

Testing:
```bash
# Test with project-specific config
cd ~/project-with-tts-config
nvim test.lua
# Press <leader>at -> should see "TTS enabled (project)"
# Verify .claude/tts/tts-config.sh changed

# Test with only global config
cd ~/project-without-tts-config
nvim test.lua
# Press <leader>at -> should see "TTS enabled (global)"
# Verify ~/.config/.claude/tts/tts-config.sh changed

# Test with no config
cd /tmp
rm -rf .claude
nvim test.txt
# Press <leader>at -> should see error notification about missing config
# Should mention "<leader>ac" command

# Test notification format
# Verify:
# - Notification uses ERROR category (always visible)
# - Message is plain text (no emojis in content)
# - Keybinding shown as "<leader>ac" (plain text)
# - Context includes project_root for debugging
```

Expected Outcomes:
- Project-specific config toggled when available
- Global config used as fallback
- Clear error message when no config exists
- Notifications follow NOTIFICATIONS.md standards
- Works consistently across projects

## Testing Strategy

### Manual Testing Scenarios

1. **Project-specific config exists**
   - Create `.claude/tts/tts-config.sh` in project root
   - Toggle with `<leader>at`
   - Verify project file modified, not global
   - Verify notification says "(project)"

2. **Only global config exists**
   - Remove project-specific config
   - Toggle with `<leader>at`
   - Verify global file modified
   - Verify notification says "(global)"

3. **No config exists**
   - Remove both configs
   - Toggle with `<leader>at`
   - Verify error notification appears
   - Verify message mentions `<leader>ac`
   - Verify no crash or silent failure

4. **Permission errors**
   - Make project config read-only
   - Toggle with `<leader>at`
   - Verify error notification with clear message

5. **Multiple projects**
   - Open Neovim in project A (has config)
   - Toggle TTS -> project A config changes
   - Open Neovim in project B (no config)
   - Toggle TTS -> global config changes
   - Open Neovim in project A again
   - Toggle TTS -> project A config changes again

### Validation Commands

```bash
# Check project-specific config
cat .claude/tts/tts-config.sh | grep "^TTS_ENABLED="

# Check global config
cat ~/.config/.claude/tts/tts-config.sh | grep "^TTS_ENABLED="

# Test notification module
nvim -c "lua require('neotex.util.notifications').editor('Test', require('neotex.util.notifications').categories.USER_ACTION)" -c "q"
```

## Documentation Requirements

### Code Comments

Add comments to clarify:
- Project root detection strategy (`vim.fn.getcwd()`)
- Path resolution priority (project > global)
- Notification protocol usage
- Helper function purpose

Example:
```lua
-- Project root detection: use cwd for consistency with other modules
local project_root = vim.fn.getcwd()

-- Path priority: project-specific config takes precedence over global
local project_config = project_root .. "/.claude/tts/tts-config.sh"
local global_config = vim.fn.expand('$HOME') .. "/.config/.claude/tts/tts-config.sh"
```

### Inline Documentation

Document the `toggle_tts_config` helper function:
```lua
-- Toggle TTS_ENABLED in the specified config file
-- @param config_path string Absolute path to tts-config.sh
-- @param is_project_specific boolean True if project-local, false if global
-- @return success boolean True if toggle succeeded
-- @return message string Success message ("TTS enabled" or "TTS disabled")
-- @return error string Error message if success is false
```

### User Documentation

No external documentation needed - behavior is intuitive:
- `<leader>at` toggles TTS
- Prefers project-specific config when available
- Error message guides user to create config via `<leader>ac`

## Dependencies

### Internal Dependencies
- `neotex.util.notifications` module (already exists)
- `vim.fn.getcwd()` (built-in)
- `vim.fn.filereadable()` (built-in)
- `vim.fn.expand()` (built-in)

### External Dependencies
None

### File Dependencies
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (modify)
- `/home/benjamin/.config/nvim/lua/neotex/util/notifications.lua` (import only)
- `/home/benjamin/.config/nvim/docs/NOTIFICATIONS.md` (reference only)

## Risks and Mitigation

### Risk 1: Project Root Detection
**Risk**: `vim.fn.getcwd()` might not always be project root (e.g., if user changes directory)
**Likelihood**: Medium - users can `:cd` to different directories
**Impact**: Low - TTS would toggle config in unexpected location
**Mitigation**:
- Document behavior clearly in code comments
- Consider alternative: search upward for `.git` or `.claude/` directory
- Accept this limitation for v1 (consistent with other modules)

### Risk 2: Notification Module Not Loaded
**Risk**: `require('neotex.util.notifications')` might fail if module is missing
**Likelihood**: Very low - module exists and is core to config
**Impact**: High - keymap would error on execution
**Mitigation**:
- Use `pcall()` around require if concerned
- Test notification module import during Phase 1

### Risk 3: User Confusion About Config Location
**Risk**: Users might not understand which config is being toggled
**Likelihood**: Medium - multiple config files can be confusing
**Impact**: Low - just toggle the wrong file
**Mitigation**:
- Include scope indicator in notification "(project)" or "(global)"
- Include config_path in notification context for debugging
- Consider adding which config path to notification message

### Risk 4: Race Conditions in Multi-Instance Scenarios
**Risk**: Multiple Neovim instances toggling same file simultaneously
**Likelihood**: Very low - rare use case
**Impact**: Low - file might be in inconsistent state
**Mitigation**:
- Accept this limitation
- File operations are atomic at OS level
- Last write wins (acceptable for toggle operation)

## Notes

### Design Decisions

#### Why Not Search for `.git` or `.claude/` Directory?
**Considered**: Search upward from current file to find project root markers
**Decision**: Use `vim.fn.getcwd()` for consistency with existing modules

**Reasoning**:
- Consistent with `bufferline.lua`, `worktree.lua`, `parser.lua`
- Simpler implementation
- Predictable behavior
- Users control project root with `:cd`

#### Why Not Create Config Automatically?
**Considered**: Auto-create `.claude/tts/tts-config.sh` if missing
**Decision**: Show notification directing user to `<leader>ac` command

**Reasoning**:
- User might want global config, not project-specific
- `<leader>ac` provides proper configuration wizard
- Avoid unexpected file creation
- Follow principle of least surprise

#### Why Include Scope in Notification?
**Considered**: Simple "TTS enabled/disabled" without scope indicator
**Decision**: Include "(project)" or "(global)" suffix

**Reasoning**:
- Users should know which config is being toggled
- Helps debug configuration issues
- Minimal verbosity (single word suffix)
- Consistent with notification context approach

### Future Enhancements

1. **Smart Project Root Detection**
   - Search upward for `.git`, `.claude/`, or other markers
   - Would work correctly even after `:cd` commands

2. **TTS Config Status Indicator**
   - Statusline component showing current TTS state
   - Visual indicator of project vs global config

3. **TTS Module Extraction**
   - Extract to `lua/neotex/util/tts.lua` with:
     - `get_status()` - Return true/false for TTS enabled
     - `set_enabled(bool)` - Set TTS state
     - `toggle()` - Toggle TTS state
     - `get_config_path()` - Return active config path
     - `get_config_scope()` - Return "project" or "global"

4. **Config Synchronization**
   - Command to sync project config from global
   - Command to push project config to global

5. **Multi-Project TTS Profiles**
   - Different TTS settings per project
   - Profile management UI

## Implementation Checklist

- [x] Phase 1: Add notification integration and test imports
- [x] Phase 2: Extract toggle logic to helper function
- [x] Test helper function independently
- [x] Phase 3: Implement project-specific path resolution
- [ ] Test with project-specific config (manual testing required)
- [ ] Test with global config fallback (manual testing required)
- [ ] Test with no config (error case) (manual testing required)
- [ ] Test notification format matches NOTIFICATIONS.md (manual testing required)
- [ ] Verify scope indicator appears correctly (manual testing required)
- [ ] Test from multiple projects (manual testing required)
- [x] Verify no regressions in existing functionality
- [x] Add code comments documenting design decisions
- [x] Commit changes with clear message

## References

### Files to Modify
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua` (lines 215-264)

### Files to Reference
- `/home/benjamin/.config/nvim/lua/neotex/util/notifications.lua` (notification API)
- `/home/benjamin/.config/nvim/docs/NOTIFICATIONS.md` (notification standards)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua` (getcwd() usage example)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua` (getcwd() usage example)

### Related Plans
- `/home/benjamin/.config/nvim/specs/plans/027_fix_tts_toggle_directory_dependency.md` (previous TTS toggle fix)

### Standards Documentation
- `/home/benjamin/.config/CLAUDE.md` (project standards)
- `/home/benjamin/.config/nvim/CLAUDE.md` (Neovim-specific standards)

### Neovim Documentation
- `:help vim.fn.getcwd()` - Get current working directory
- `:help vim.fn.filereadable()` - Check file existence
- `:help vim.fn.expand()` - Path expansion
- `:help pcall()` - Protected function call
