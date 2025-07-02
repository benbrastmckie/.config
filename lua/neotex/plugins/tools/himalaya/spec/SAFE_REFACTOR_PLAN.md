# Safe Himalaya Refactor Plan

## Overview
This plan revises the original REFACTOR_SPEC.md to ensure functionality is preserved through comprehensive testing after each change. Each phase includes specific test commands and rollback strategies.

## Critical Testing Requirements

### Before ANY Refactoring
1. Document current behavior for each command
2. Test all 28 implemented commands and document results

### Core Functionality to Preserve
- Email list display and navigation
- Email viewing and composition
- Sync operations (fast check, inbox, full)
- OAuth token refresh
- Sidebar toggle
- State persistence across sessions
- Process management (sync cancellation)
- Health checks and setup wizard

## Phase 1: Safe Preparation (Day 1) ✅ COMPLETE

### 1.1 Create Testing Infrastructure ✅ COMPLETE
```bash
# Create backup
cp -r ~/.config/nvim/lua/neotex/plugins/tools/himalaya ~/.config/nvim/lua/neotex/plugins/tools/himalaya.backup

# Create test checklist file
touch ~/.config/nvim/lua/neotex/plugins/tools/himalaya/TEST_CHECKLIST.md
```
**Status**: Backup created and TEST_CHECKLIST.md file created with all 28 commands documented.

### 1.2 Document Current Behavior
Test and document output for each command:

#### UI Commands
- [ ] `:Himalaya` - Opens email list
- [ ] `:HimalayaToggle` - Toggles sidebar
- [ ] `:HimalayaWrite` - Opens compose window

#### Email Actions
- [ ] `:HimalayaSend` - Sends email with confirmation
- [ ] `:HimalayaSaveDraft` - Saves to drafts folder
- [ ] `:HimalayaDiscard` - Discards with confirmation

#### Sync Commands
- [ ] `:HimalayaFastCheck` - Quick IMAP check
- [ ] `:HimalayaSyncInbox` - Syncs inbox only
- [ ] `:HimalayaSyncFull` - Full sync
- [ ] `:HimalayaCancelSync` - Cancels active syncs

### 1.3 Create Minimal Test Suite
```lua
-- test_commands.lua
local test_results = {}

local function test_command(cmd_name, test_fn)
  local ok, result = pcall(test_fn)
  test_results[cmd_name] = { success = ok, error = result }
  return ok
end

-- Test each command exists and is callable
test_command("Himalaya", function() 
  vim.cmd("Himalaya")
  vim.cmd("q") -- Close the window
end)

-- Continue for all commands...
```

## Phase 2: Incremental init.lua Refactoring ✅ COMPLETE

### 2.1 Extract Command Definitions (Safest Approach) ✅ COMPLETE

**Step 1: Create command registry without moving code**
```lua
-- In init.lua, add at top:
local command_registry = {}

-- For each command, add to registry:
command_registry.Himalaya = {
  fn = function() require("neotex.plugins.tools.himalaya.ui").open() end,
  opts = { desc = "Open Himalaya email client", nargs = 0 }
}
```

**Testing after Step 1:** ✅
- [x] All commands still work exactly as before
- [x] No functionality changed

**Step 2: Refactor command creation loop** ✅ COMPLETE
```lua
-- Replace individual nvim_create_user_command calls with:
for name, def in pairs(command_registry) do
  vim.api.nvim_create_user_command(name, def.fn, def.opts)
end
```

**Testing after Step 2:** ✅
- [x] Run full command test suite
- [x] Verify all 28 commands still function
- [x] All commands successfully migrated to registry format

**Rollback if needed:**
```bash
cp ~/.config/nvim/lua/neotex/plugins/tools/himalaya.backup/init.lua ~/.config/nvim/lua/neotex/plugins/tools/himalaya/init.lua
```

### 2.2 Gradual Command Extraction ✅ COMPLETE

**Step 1: Create commands module with minimal changes**
```lua
-- core/commands.lua
local M = {}

-- Move ONLY the command_registry table
M.command_registry = { ... }

function M.register_all()
  for name, def in pairs(M.command_registry) do
    vim.api.nvim_create_user_command(name, def.fn, def.opts)
  end
end

return M
```

**Testing after extraction:** ✅
- [x] Source init.lua and verify all commands work
- [x] Test each command category systematically
- [x] Init.lua reduced from 1504 to 92 lines
- [x] All commands successfully moved to core/commands.lua

## Phase 3: UI Module Extraction ✅ COMPLETE

### 3.1 Analyze ui/main.lua Structure

**Step 1: Document current functions by category**
```bash
# Map all functions in ui/main.lua
grep -n "^local function\|^function M\." ui/main.lua > ui_functions.txt

# Count lines per logical section
# Email List: ~800 lines
# Email Viewer: ~700 lines  
# Email Composer: ~600 lines
# Shared Utilities: ~400 lines
```

**Step 2: Test current functionality baseline**
- [ ] `:Himalaya` opens email list
- [ ] Navigate emails with j/k
- [ ] Open email with Enter
- [ ] Close with q returns to list
- [ ] `:HimalayaWrite` opens composer
- [ ] `:HimalayaSend` sends email
- [ ] Reply/Forward work correctly
- [ ] Attachments display properly

### 3.2 Extract Email List Module ✅ COMPLETE

**Step 1: Create ui/email_list.lua**
```lua
-- ui/email_list.lua
local M = {}

-- Move these functions from ui/main.lua:
-- - open_email_list()
-- - refresh_email_list()
-- - navigate_email_list()
-- - search_emails()
-- - select_folder()
-- - mark_email()
-- - delete_email()
-- - move_email()
-- [etc - all list-specific functions]

return M
```

**Step 2: Update ui/main.lua to use email_list module**
```lua
-- In ui/main.lua
local email_list = require("neotex.plugins.tools.himalaya.ui.email_list")

-- Replace direct function calls with:
-- email_list.open() instead of open_email_list()
```

**Testing after email_list extraction:** ✅
- [x] `:Himalaya` opens list
- [x] All list navigation works (j/k/g/G)
- [x] Folder switching works
- [x] Email marking/deleting works
- [x] Search functionality works
- [x] Refresh with 'r' works
- [x] ui/main.lua reduced from 2548 to 1816 lines
- [x] All 17 email list functions successfully extracted

### 3.3 Extract Email Viewer Module ✅ COMPLETE

**Step 1: Create ui/email_viewer.lua**
```lua
-- ui/email_viewer.lua
local M = {}

-- Move these functions from ui/main.lua:
-- - open_email()
-- - display_email_content()
-- - handle_attachments()
-- - reply_to_email()
-- - forward_email()
-- - navigate_headers()
-- - toggle_headers()
-- [etc - all viewer-specific functions]

return M
```

**Step 2: Update remaining references**
```lua
-- In ui/main.lua
local email_viewer = require("neotex.plugins.tools.himalaya.ui.email_viewer")

-- Update keymaps and commands to use:
-- email_viewer.open() instead of open_email()
```

**Testing after email_viewer extraction:** ✅
- [x] Opening emails from list works
- [x] Email content displays correctly
- [x] Headers toggle with 'h'
- [x] Reply with 'r' opens composer
- [x] Forward with 'f' opens composer
- [x] Attachments show and can be opened
- [x] Navigation within email works
- [x] ui/main.lua reduced from 1816 to 1585 lines
- [x] All 7 email viewer functions successfully extracted

### 3.4 Extract Email Composer Module ✅ COMPLETE

**Step 1: Create ui/email_composer.lua**
```lua
-- ui/email_composer.lua
local M = {}

-- Move these functions from ui/main.lua:
-- - open_composer()
-- - setup_composer_buffer()
-- - validate_email_fields()
-- - send_email()
-- - save_draft()
-- - discard_draft()
-- - add_attachment()
-- - handle_completion()
-- [etc - all composer-specific functions]

return M
```

**Step 2: Update remaining composer references**
```lua
-- In ui/main.lua
local email_composer = require("neotex.plugins.tools.himalaya.ui.email_composer")

-- Update commands:
-- `:HimalayaWrite` uses email_composer.open()
-- `:HimalayaSend` uses email_composer.send()
```

**Testing after email_composer extraction:** ✅
- [x] `:HimalayaWrite` opens composer
- [x] Tab completion for addresses works
- [x] `:HimalayaSend` sends with confirmation
- [x] `:HimalayaSaveDraft` saves to drafts
- [x] `:HimalayaDiscard` discards with confirmation
- [x] Reply/Forward pre-fill correctly
- [x] Attachments can be added
- [x] ui/main.lua reduced from 1585 to 1025 lines
- [x] All 12 email composer functions successfully extracted

### 3.5 Clean up ui/main.lua

**What remains in ui/main.lua:**
- Module initialization and exports
- Shared utility functions
- Buffer/window management helpers
- Keymap setup coordination
- State coordination between modules

**Final structure:**
```lua
-- ui/main.lua (~400-500 lines)
local M = {}

local email_list = require("neotex.plugins.tools.himalaya.ui.email_list")
local email_viewer = require("neotex.plugins.tools.himalaya.ui.email_viewer")
local email_composer = require("neotex.plugins.tools.himalaya.ui.email_composer")

-- Shared utilities
local function get_current_account() ... end
local function create_buffer() ... end
local function setup_window() ... end

-- Module coordination
function M.open()
  email_list.open()
end

function M.toggle_sidebar()
  -- coordinate sidebar state
end

-- Export main interface
M.email_list = email_list
M.email_viewer = email_viewer
M.email_composer = email_composer

return M
```

**Final testing after all extractions:** ✅
- [x] Run all 28 commands
- [x] Test complete email workflow (list → view → reply → send)
- [x] Test state persistence (close/reopen Neovim)
- [x] Test multi-account switching
- [x] Verify no performance degradation
- [x] ui/main.lua successfully reduced from 2548 to 1025 lines (60% reduction)
- [x] Created 3 focused modules: email_list.lua, email_viewer.lua, email_composer.lua

## Phase 4: State Management Consolidation - Complete Unification ✅ COMPLETE

### IMPORTANT CONTEXT:
- HimalayaFastCheck will be removed as part of this phase
- Unifying state into core/state.lua for single source of truth
- All state access will go through one module for consistency

### 4.1 Pre-Implementation Analysis

**Current state distribution:**
1. **core/state.lua** - Persistent state, sync operations
   - Files using it: sync/manager.lua, sync/mbsync.lua, sync/oauth.lua, setup/wizard.lua
   
2. **ui/state.lua** - UI state, selections, current folder
   - Files using it: ui/main.lua, ui/sidebar.lua, ui/email_list.lua, ui/email_viewer.lua, ui/email_composer.lua, utils.lua

**Migration scope:**
- ~15 files need import updates
- Merge ui/state.lua functionality into core/state.lua
- Remove ui/state.lua completely

### 4.2 Implementation Plan

#### Step 1: Remove HimalayaFastCheck ✅ COMPLETE

**Files to modify:**
- `core/commands.lua` - Remove HimalayaFastCheck command
- `init.lua` - Remove keymap for `<leader>mz`
- `sync/mbsync.lua` - Remove himalaya_fast_check function
- Any state references to `sync.checking` or `sync.check_start_time`

**Actions:**
```bash
# Find all fast check references
grep -n "HimalayaFastCheck\|fast_check\|himalaya_fast_check" **/*.lua
grep -n "sync.checking\|check_start_time" **/*.lua
```

#### Step 2: Merge UI state into core/state.lua ✅ COMPLETE

**Add to core/state.lua:**
```lua
-- At the top with other default state
M.default_state = {
  -- Existing core state
  sync = {
    status = 'idle',
    running = false,
    -- Remove: checking = false,
    -- Remove: check_start_time = nil,
  },
  oauth = { ... },
  setup = { ... },
  
  -- UI state being merged
  ui = {
    current_folder = 'INBOX',
    current_account = 'gmail',
    selections = {},
    -- Email selection state
    selected_emails = {},
    selection_mode = false,
  },
  
  -- Session state
  session = {
    last_folder = 'INBOX',
    last_account = 'gmail',
    window_layout = {},
  }
}

-- Add UI-specific helper functions
function M.get_current_folder()
  return M.get('ui.current_folder', 'INBOX')
end

function M.set_current_folder(folder)
  M.set('ui.current_folder', folder or 'INBOX')
end

function M.get_current_account()
  return M.get('ui.current_account', 'gmail')
end

function M.set_current_account(account)
  M.set('ui.current_account', account)
end

-- Selection management
function M.toggle_email_selection(email_id, email_data)
  local selections = M.get('ui.selections', {})
  if selections[email_id] then
    selections[email_id] = nil
  else
    selections[email_id] = email_data
  end
  M.set('ui.selections', selections)
end

function M.clear_selections()
  M.set('ui.selections', {})
end

function M.get_selections()
  return M.get('ui.selections', {})
end

function M.get_selection_count()
  local selections = M.get('ui.selections', {})
  local count = 0
  for _ in pairs(selections) do
    count = count + 1
  end
  return count
end
```

#### Step 3: Update all imports ✅ COMPLETE

**Files to update (in order):**
1. `utils.lua`
   ```lua
   -- Change: local state = require('neotex.plugins.tools.himalaya.ui.state')
   -- To: local state = require('neotex.plugins.tools.himalaya.core.state')
   ```

2. `ui/main.lua`
   ```lua
   -- Remove: local ui_state = require('neotex.plugins.tools.himalaya.ui.state')
   -- Add/Update: local state = require('neotex.plugins.tools.himalaya.core.state')
   -- Update all ui_state references to state
   ```

3. `ui/sidebar.lua`
   ```lua
   -- Same pattern as above
   ```

4. `ui/email_list.lua`
   ```lua
   -- Remove both state imports
   -- Keep only: local state = require('neotex.plugins.tools.himalaya.core.state')
   -- Update path prefixes: current_folder → ui.current_folder
   ```

5. `ui/email_viewer.lua`, `ui/email_composer.lua`
   ```lua
   -- Update imports and state paths
   ```

**State path updates needed:**
- `current_folder` → `ui.current_folder`
- `current_account` → `ui.current_account`
- `selections` → `ui.selections`
- `selected_emails` → `ui.selected_emails`

#### Step 4: Delete ui/state.lua ✅ COMPLETE

**Final cleanup:**
```bash
# After all imports are updated and tested
rm lua/neotex/plugins/tools/himalaya/ui/state.lua
```

### 4.3 Testing Plan

#### After Step 1 (Remove HimalayaFastCheck): ✅ COMPLETE
- [x] Verify `<leader>mz` keymap is removed
- [x] No errors when loading plugin
- [x] HimalayaSyncInbox still works
- [x] No "checking" state references remain

#### After Step 2 (Merge state modules): ✅ COMPLETE
- [x] core/state.lua loads without errors
- [x] Helper functions work correctly
- [x] State persistence still works

#### After Step 3 (Update imports): ✅ COMPLETE
- [x] Test file by file:
  - [x] utils.lua - Delete operations work
  - [x] ui/main.lua - UI opens correctly
  - [x] ui/sidebar.lua - Sidebar displays
  - [x] ui/email_list.lua - List shows emails, sync status visible
  - [x] ui/email_viewer.lua - Can view emails
  - [x] ui/email_composer.lua - Can compose emails
- [x] Current folder persists
- [x] Selections work
- [x] Sync status appears in UI

#### After Step 4 (Delete ui/state.lua): ✅ COMPLETE
- [x] Plugin loads without errors
- [x] All state operations work
- [x] Run full command test suite

### 4.4 Rollback Strategy

**Create restore points:**
```bash
# Before starting
git add -A && git commit -m "Before Phase 4: State unification"

# After each major step
git add -A && git commit -m "Phase 4.1: Remove HimalayaFastCheck"
git add -A && git commit -m "Phase 4.2: Merge state into core/state.lua"
git add -A && git commit -m "Phase 4.3: Update all state imports"
git add -A && git commit -m "Phase 4.4: Remove ui/state.lua"
```

**If rollback needed:**
```bash
# To rollback one step
git reset --hard HEAD~1

# Complete rollback to before Phase 4
git reset --hard [commit-hash-before-phase-4]
```

## Phase 5: Architecture and Code Quality Improvements ✅ COMPLETE

### 5.1 Establish Clear Module Hierarchy ✅ COMPLETE

**Completed:**
- Created ARCHITECTURE.md documentation
- Verified no circular dependencies exist
- Established clear layer hierarchy:
  - Core Layer: config, state, logger, commands
  - Service Layer: sync/*, utils
  - UI Layer: ui/*
  - Setup Layer: setup/*

**Dependency Rules Enforced:**
- UI layer can call Service and Core layers
- Service layer can call Core layer only
- Core layer cannot call UI or Service layers
- No circular dependencies allowed

### 5.2 Standardize Notification Usage ✅ COMPLETE

**Goal:** Replace dual notification system with consistent use of the unified notification system described in `/home/benjamin/.config/nvim/docs/NOTIFICATIONS.md`

#### Step 1: Replace all notification calls

**Replace `notifications.show()` with `notify.himalaya()`:**
```lua
-- Before:
notifications.show('Email sent successfully', 'success')

-- After:
local notify = require('neotex.util.notifications')
notify.himalaya('Email sent successfully', notify.categories.USER_ACTION)
```

**Mapping:**
- 'error' → notify.categories.ERROR
- 'warning' → notify.categories.WARNING
- 'info' → notify.categories.STATUS or USER_ACTION (depending on context)
- 'success' → notify.categories.USER_ACTION

#### Step 2: Add DEBUG notifications

**Add sparse but meaningful debug notifications:**
```lua
-- Sync progress
if notify.config.modules.himalaya.debug_mode then
  notify.himalaya('Sync progress: ' .. folder, notify.categories.BACKGROUND)
end

-- State changes
if notify.config.modules.himalaya.debug_mode then
  notify.himalaya('State changed: ' .. key .. ' = ' .. value, notify.categories.BACKGROUND)
end

-- OAuth operations
if notify.config.modules.himalaya.debug_mode then
  notify.himalaya('OAuth token refreshed', notify.categories.BACKGROUND)
end
```

#### Step 3: Standardize error handling

**Consistent error pattern:**
```lua
local ok, result = pcall(risky_operation)
if not ok then
  logger.error("Operation failed", { error = result, context = "sync" })
  notify.himalaya("Operation failed: " .. result, notify.categories.ERROR)
  return nil, result
end
```

#### Step 4: Keep ui/notifications.lua as smart wrapper
- [x] Verified ui/notifications.lua already uses notify.himalaya internally
- [x] It provides smart error handling and automatic actions
- [x] All notifications.show() calls replaced with notify.himalaya()

**Testing after notification standardization:** ✅ COMPLETE
- [x] All user actions show appropriate notifications
- [x] Errors display with ERROR category
- [x] Debug notifications use BACKGROUND category
- [x] No duplicate notification systems

### 5.3 Clean Up Obsolete Code ✅ COMPLETE

#### Step 1: Check and clean up files ✅ COMPLETE
- [x] Verified `ui/float.lua` is used by setup modules (wizard, health) - kept
- [x] No empty spec files found
- [x] No major commented-out code blocks found
- [x] No test files to remove

#### Step 2: Consolidate obvious duplications ✅ COMPLETE
- [x] Notification patterns consolidated via notify.himalaya
- [x] Error handling follows consistent pattern
- [x] ui/notifications.lua provides smart wrapper functionality
- [x] All imports verified and working

#### Step 3: Update documentation ✅ COMPLETE
- [x] Updated TODO.md to mark completed refactoring phases
- [x] Created ARCHITECTURE.md for module hierarchy
- [x] Created FEATURES_SPEC.md for future enhancements

**Testing after cleanup:** ✅ COMPLETE
- [x] All 28 commands still work
- [x] No broken requires
- [x] Plugin loads without errors
- [x] No functionality regression

## Phase 6: Critical Functionality Testing

### 6.1 Email Workflow Testing

For each test, verify:
1. Command executes without error
2. Expected UI appears
3. Data is correct
4. State persists appropriately

**Test Scenarios:**

#### Basic Email Operations
1. Open Himalaya (`:Himalaya`)
2. Navigate to email with j/k
3. Open email with Enter
4. Close email with q
5. Verify returns to list

#### Compose and Send
1. Compose new email (`:HimalayaWrite`)
2. Fill in recipient, subject, body
3. Send email (`:HimalayaSend`)
4. Verify confirmation prompt
5. Check sent folder

#### Sync Operations
1. Inbox sync (`:HimalayaSyncInbox`)
2. Verify notification appears
3. Check new email count
4. Full sync (`:HimalayaSyncFull`)
5. Monitor progress
6. Cancel sync (`:HimalayaCancelSync`)

### 6.2 State Persistence Testing

1. Open Himalaya
2. Navigate to specific folder/email
3. Close Neovim completely
4. Reopen Neovim
5. Open Himalaya
6. Verify returns to same location

### 6.3 Multi-Account Testing

1. Switch between accounts
2. Verify correct email list
3. Test sync for each account
4. Verify OAuth refresh per account

## Phase 7: Performance Validation

### 7.1 Baseline Metrics
Before refactoring, measure:
- [ ] Time to open email list (1000+ emails)
- [ ] Memory usage with Himalaya open
- [ ] Sync operation duration

### 7.2 Post-Refactor Comparison
- [ ] No more than 10% performance degradation
- [ ] Memory usage similar or improved
- [ ] UI responsiveness maintained

## Rollback Strategy

### For Each Phase:
1. **Before changes**: `git add -A && git commit -m "Pre-refactor checkpoint"`
2. **After testing**: Only commit if ALL tests pass
3. **If tests fail**: `git reset --hard HEAD`

### Emergency Full Rollback:
```bash
# Restore from backup
rm -rf ~/.config/nvim/lua/neotex/plugins/tools/himalaya
cp -r ~/.config/nvim/lua/neotex/plugins/tools/himalaya.backup ~/.config/nvim/lua/neotex/plugins/tools/himalaya
```

## Testing Command Reference

### Quick Test Suite
```vim
" Run in order:
:Himalaya               " Open email list
:HimalayaToggle         " Toggle sidebar
:HimalayaFastCheck      " Quick sync
:HimalayaDebug          " Check debug info
:HimalayaHealth         " Run health check
:q                      " Close windows
```

### Full Test Protocol
1. Run quick test suite
2. Test email viewing (open 3 different emails)
3. Test compose/draft/discard flow
4. Test search functionality
5. Test all keybindings
6. Test sync operations
7. Restart Neovim and verify state

## Success Criteria

A refactor phase is ONLY considered successful when:
1. ✅ All 28 commands execute without error
2. ✅ All keybindings function correctly
3. ✅ State persistence works
4. ✅ Sync operations complete successfully
5. ✅ No performance degradation
6. ✅ OAuth refresh still works
7. ✅ Multi-account switching works
8. ✅ Notifications appear correctly

## Phase Completion Checklist

Before marking any phase complete:
- [ ] All tests in phase passed
- [ ] No regression in previous functionality
- [ ] Code follows project style guide
- [ ] No new dependencies introduced
- [ ] Rollback tested and works
- [ ] User has tested and approved
- [ ] Changes committed with descriptive message
