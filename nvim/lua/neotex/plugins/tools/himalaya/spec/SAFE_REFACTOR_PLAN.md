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

## Phase 1: Safe Preparation (Day 1)

### 1.1 Create Testing Infrastructure
```bash
# Create backup
cp -r ~/.config/nvim/lua/neotex/plugins/tools/himalaya ~/.config/nvim/lua/neotex/plugins/tools/himalaya.backup

# Create test checklist file
touch ~/.config/nvim/lua/neotex/plugins/tools/himalaya/TEST_CHECKLIST.md
```

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

## Phase 2: Incremental init.lua Refactoring

### 2.1 Extract Command Definitions (Safest Approach)

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

**Testing after Step 1:**
- [ ] All commands still work exactly as before
- [ ] No functionality changed

**Step 2: Refactor command creation loop**
```lua
-- Replace individual nvim_create_user_command calls with:
for name, def in pairs(command_registry) do
  vim.api.nvim_create_user_command(name, def.fn, def.opts)
end
```

**Testing after Step 2:**
- [ ] Run full command test suite
- [ ] Verify all 28 commands still function

**Rollback if needed:**
```bash
cp ~/.config/nvim/lua/neotex/plugins/tools/himalaya.backup/init.lua ~/.config/nvim/lua/neotex/plugins/tools/himalaya/init.lua
```

### 2.2 Gradual Command Extraction

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

**Testing after extraction:**
- [ ] Source init.lua and verify all commands work
- [ ] Test each command category systematically

## Phase 3: UI Module Extraction

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

### 3.2 Extract Email List Module

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

**Testing after email_list extraction:**
- [ ] `:Himalaya` opens list
- [ ] All list navigation works (j/k/g/G)
- [ ] Folder switching works
- [ ] Email marking/deleting works
- [ ] Search functionality works
- [ ] Refresh with 'r' works

### 3.3 Extract Email Viewer Module

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

**Testing after email_viewer extraction:**
- [ ] Opening emails from list works
- [ ] Email content displays correctly
- [ ] Headers toggle with 'h'
- [ ] Reply with 'r' opens composer
- [ ] Forward with 'f' opens composer
- [ ] Attachments show and can be opened
- [ ] Navigation within email works

### 3.4 Extract Email Composer Module

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

**Testing after email_composer extraction:**
- [ ] `:HimalayaWrite` opens composer
- [ ] Tab completion for addresses works
- [ ] `:HimalayaSend` sends with confirmation
- [ ] `:HimalayaSaveDraft` saves to drafts
- [ ] `:HimalayaDiscard` discards with confirmation
- [ ] Reply/Forward pre-fill correctly
- [ ] Attachments can be added

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

**Final testing after all extractions:**
- [ ] Run all 28 commands
- [ ] Test complete email workflow (list → view → reply → send)
- [ ] Test state persistence (close/reopen Neovim)
- [ ] Test multi-account switching
- [ ] Verify no performance degradation

## Phase 4: Architecture Improvements

### 4.1 Establish Clear Module Hierarchy

After completing the extractions, enforce a clear dependency hierarchy:

```
┌─────────────┐
│   init.lua  │
└──────┬──────┘
       │
┌──────┴───────────────────────────────────┐
│            Core Layer                    │
├──────────────────────────────────────────┤
│ config.lua    │ state.lua                │
│ logger.lua    │ utils.lua (CLI ops)      │
└──────────────┬───────────────────────────┘
               │
┌──────────────┴───────────────────────────┐
│          Service Layer                   │
├──────────────────────────────────────────┤
│ sync/manager.lua │ sync/oauth.lua        │
│ sync/mbsync.lua  │ sync/lock.lua         │
└──────────────┬───────────────────────────┘
               │
┌──────────────┴───────────────────────────┐
│            UI Layer                      │
├──────────────────────────────────────────┤
│ ui/main.lua      │ ui/sidebar.lua        │
│ ui/email_list.lua│ ui/email_viewer.lua   │
│ ui/email_composer.lua│ ui/notifications.lua│
└──────────────────────────────────────────┘
```

**Dependency Rules:**
- UI layer can call Service and Core layers
- Service layer can call Core layer only
- Core layer cannot call UI or Service layers
- No circular dependencies allowed

**Testing after hierarchy enforcement:**
- [ ] Verify no circular requires with dependency analysis
- [ ] All commands still function correctly
- [ ] State flows properly between layers

### 4.2 Standardize Error Handling

**Step 1: Create consistent error handling pattern**

Update all modules to use:
```lua
local ok, result = pcall(function_that_might_fail)
if not ok then
  require("neotex.plugins.tools.himalaya.core.logger").error("Context: " .. result)
  require("neotex.util.notifications").notify("Action failed: " .. result, "error")
  return nil, result
end
```

**Step 2: Centralize notification handling**
- Use `neotex.util.notifications` for user-facing messages
- Use `core.logger` for debug/error logging
- Remove duplicate notification code

**Testing after error handling updates:**
- [ ] Errors display user-friendly notifications
- [ ] Debug logs capture detailed error info
- [ ] No duplicate error messages
- [ ] Commands handle errors gracefully

### 4.3 Clean Up Obsolete Code

**Step 1: Remove unused files**
- [ ] Delete `ui/float.lua` (unused)
- [ ] Delete `ui/REFACTOR.md` (obsolete)
- [ ] Remove empty spec files

**Step 2: Clean up code**
- [ ] Remove commented-out code blocks
- [ ] Update TODO.md to reflect completed items
- [ ] Remove redundant `ui/init.lua` if just re-exporting

**Testing after cleanup:**
- [ ] All commands still work
- [ ] No broken requires
- [ ] Module imports still resolve

## Phase 5: State Management Consolidation

### 5.1 Analyze State Usage First

**Step 1: Document all state access points**
```bash
# Find all state references
grep -n "state\." *.lua ui/*.lua core/*.lua sync/*.lua
```

### 5.2 Create Migration Path

**Step 1: Add compatibility layer**
```lua
-- In ui/state.lua
local core_state = require("neotex.plugins.tools.himalaya.core.state")

-- Proxy all calls to core.state
return setmetatable({}, {
  __index = function(_, key) return core_state[key] end,
  __newindex = function(_, key, value) core_state[key] = value end
})
```

**Testing with compatibility layer:**
- [ ] All state-dependent features work
- [ ] UI state persists
- [ ] Runtime state updates correctly

**Step 2: Gradually update references**
- Update one module at a time
- Test after each module update

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
1. Fast check (`:HimalayaFastCheck`)
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
