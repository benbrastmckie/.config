# Sync Status Refactor Plan

## Problem Statement

The current sync status system has inconsistent behavior between:
- `<leader>ms` (HimalayaSyncInbox) - Shows sync status correctly
- `<leader>mz` (HimalayaFastCheck) - Fails to show sync status
- `<leader>mi` (HimalayaInfo) - Should show info for both sync types

### Root Causes

1. **Dual State Systems**: Mixed use of `core.state` and `ui.state` modules
2. **Inconsistent State Management**: Different sync types set different state variables
3. **Complex Conditional Logic**: The UI checks multiple conditions that don't cover all cases
4. **Tight Coupling**: UI display logic is tightly coupled to mbsync implementation

## Design Goals

1. **Unified State Management**: Single source of truth for all sync operations
2. **Clear Sync Types**: Distinguish between full sync and fast check operations
3. **Consistent UI Updates**: Both sync types should update the sidebar identically
4. **Comprehensive Info Display**: `<leader>mi` shows status for all sync types

## Proposed Architecture

### 1. Sync State Structure

Create a unified sync state structure in `core.state`:

```lua
sync = {
  -- Common fields for all sync types
  type = nil,           -- 'full' | 'fast_check' | nil
  status = 'idle',      -- 'idle' | 'running' | 'completed' | 'error'
  message = nil,        -- Human-readable status message
  start_time = nil,     -- When sync started
  end_time = nil,       -- When sync ended
  
  -- Full sync specific (mbsync)
  full = {
    channel = nil,      -- Which channel is syncing
    progress = {
      folders_total = 0,
      folders_done = 0,
      messages_total = 0,
      messages_processed = 0,
      current_folder = nil,
      current_operation = nil,
    }
  },
  
  -- Fast check specific (himalaya)
  fast_check = {
    account = nil,      -- Which account is being checked
    has_new = false,    -- Whether new emails were found
    new_count = 0,      -- Number of new emails
    checked_at = nil,   -- Last check timestamp
  },
  
  -- History for <leader>mi
  history = {
    last_full_sync = nil,     -- Timestamp of last full sync
    last_fast_check = nil,    -- Timestamp of last fast check
    last_error = nil,         -- Last error message
    total_syncs_today = 0,    -- Counter for daily syncs
    total_checks_today = 0,   -- Counter for daily checks
  }
}
```

### 2. Sync Manager Module

Create `sync/manager.lua` to handle all sync operations:

```lua
local M = {}

-- Start any sync operation
function M.start_sync(sync_type, options)
  -- Set common state
  state.set('sync.type', sync_type)
  state.set('sync.status', 'running')
  state.set('sync.start_time', os.time())
  state.set('sync.message', M.get_status_message(sync_type))
  
  -- Notify UI to update
  M.notify_ui_update()
end

-- Complete any sync operation
function M.complete_sync(sync_type, result)
  state.set('sync.status', result.success and 'completed' or 'error')
  state.set('sync.end_time', os.time())
  
  -- Update history
  M.update_history(sync_type, result)
  
  -- Clear after delay
  vim.defer_fn(function()
    if state.get('sync.type') == sync_type then
      state.set('sync.type', nil)
      state.set('sync.status', 'idle')
    end
  end, 5000)
  
  -- Notify UI to update
  M.notify_ui_update()
end

-- Get human-readable status message
function M.get_status_message(sync_type)
  if sync_type == 'full' then
    return 'ó Syncing emails...'
  elseif sync_type == 'fast_check' then
    return '= Checking for new mail...'
  end
  return nil
end

-- Notify UI components to update
function M.notify_ui_update()
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local main = require('neotex.plugins.tools.himalaya.ui.main')
  
  if sidebar.is_open() then
    main.refresh_sidebar_header()
  end
end

return M
```

### 3. Refactored Commands

#### HimalayaSyncInbox (`<leader>ms`)
```lua
cmd('HimalayaSyncInbox', function()
  local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
  
  -- Start sync through manager
  sync_manager.start_sync('full', {
    channel = channel,
    account = account_name
  })
  
  -- Run actual mbsync
  mbsync.sync(channel, {
    on_progress = function(progress)
      state.set('sync.full.progress', progress)
      sync_manager.notify_ui_update()
    end,
    callback = function(success, error)
      sync_manager.complete_sync('full', {
        success = success,
        error = error
      })
    end
  })
end)
```

#### HimalayaFastCheck (`<leader>mz`)
```lua
cmd('HimalayaFastCheck', function()
  local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
  
  -- Start check through manager
  sync_manager.start_sync('fast_check', {
    account = account_name
  })
  
  -- Run actual check
  mbsync.himalaya_fast_check({
    auto_refresh = true,
    callback = function(status, error)
      sync_manager.complete_sync('fast_check', {
        success = status ~= nil,
        error = error,
        has_new = status and status.has_new,
        new_count = status and status.new_count
      })
      
      -- Handle new email prompt...
    end
  })
end)
```

### 4. Simplified UI Status Display

Refactor `get_sync_status_line_detailed()` in `ui/main.lua`:

```lua
function M.get_sync_status_line_detailed()
  local state = require('neotex.plugins.tools.himalaya.core.state')
  
  -- Get current sync state
  local sync_type = state.get('sync.type')
  local sync_status = state.get('sync.status')
  
  -- Not syncing
  if not sync_type or sync_status ~= 'running' then
    return nil
  end
  
  -- Get base message
  local message = state.get('sync.message')
  if not message then
    return nil
  end
  
  -- Add elapsed time
  local start_time = state.get('sync.start_time')
  if start_time then
    local elapsed = os.time() - start_time
    message = message .. string.format(" (%ds)", elapsed)
  end
  
  -- Add progress for full sync
  if sync_type == 'full' then
    local progress = state.get('sync.full.progress')
    if progress and progress.current_folder then
      message = message .. string.format(" - %s", progress.current_folder)
    end
  end
  
  return message
end
```

### 5. Enhanced Info Display (`<leader>mi`)

Update the info display to show both sync types:

```lua
local function get_himalaya_info()
  local lines = {}
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local history = state.get('sync.history', {})
  
  -- Current sync status
  local sync_type = state.get('sync.type')
  if sync_type then
    table.insert(lines, '=== Current Sync ===')
    table.insert(lines, 'Type: ' .. sync_type)
    table.insert(lines, 'Status: ' .. state.get('sync.status'))
    table.insert(lines, 'Message: ' .. (state.get('sync.message') or 'N/A'))
    table.insert(lines, '')
  end
  
  -- Sync history
  table.insert(lines, '=== Sync History ===')
  table.insert(lines, 'Last full sync: ' .. format_time_ago(history.last_full_sync))
  table.insert(lines, 'Last fast check: ' .. format_time_ago(history.last_fast_check))
  table.insert(lines, 'Full syncs today: ' .. (history.total_syncs_today or 0))
  table.insert(lines, 'Fast checks today: ' .. (history.total_checks_today or 0))
  
  if history.last_error then
    table.insert(lines, '')
    table.insert(lines, '=== Last Error ===')
    table.insert(lines, history.last_error)
  end
  
  return lines
end
```

## Implementation Steps

### Phase 1: Core Infrastructure
1. Create `sync/manager.lua` module
2. Update state structure in `core/state.lua`
3. Add state migration for existing data

### Phase 2: Command Updates
1. Refactor `HimalayaSyncInbox` to use sync manager
2. Refactor `HimalayaFastCheck` to use sync manager
3. Update error handling to use unified system

### Phase 3: UI Updates
1. Simplify `get_sync_status_line_detailed()`
2. Remove complex conditional logic
3. Ensure consistent sidebar updates

### Phase 4: Info Display
1. Update `<leader>mi` to show comprehensive sync info
2. Add sync history tracking
3. Add daily counters with reset logic

### Phase 5: Testing & Polish
1. Test both sync types with sidebar open/closed
2. Test OAuth refresh during fast check
3. Test error scenarios
4. Add debug commands for testing state

## Benefits

1. **Consistency**: Both sync types use the same state management
2. **Simplicity**: UI only needs to check one place for status
3. **Extensibility**: Easy to add new sync types in the future
4. **Debuggability**: Clear state structure makes debugging easier
5. **User Experience**: Consistent status display and comprehensive info

## Migration Strategy

1. Implement new system alongside existing
2. Add feature flag to toggle between old/new
3. Test thoroughly with both systems
4. Remove old system once stable

## Testing Checklist

- [ ] `<leader>ms` shows sync status in sidebar
- [ ] `<leader>mz` shows check status in sidebar
- [ ] Status updates show elapsed time
- [ ] Status clears after completion
- [ ] OAuth refresh works during fast check
- [ ] `<leader>mi` shows info for both sync types
- [ ] Sync history persists across sessions
- [ ] Daily counters reset at midnight
- [ ] Error handling works for both types
- [ ] Debug mode shows detailed logging