# Draft State Management API Documentation

This document describes the draft state management functions added in Phase 1 of the Draft Integration.

## Overview

The draft system now integrates with the centralized state management system in `core/state.lua`. This provides:
- Single source of truth for draft data
- Persistence across Neovim sessions
- Recovery tracking for unsaved drafts
- Sync status management

## State Structure

The draft state is stored under the `draft` section of the centralized state:

```lua
draft = {
  -- Active drafts mapped by buffer ID
  drafts = {
    ["buffer_id"] = {
      local_id = "unique_id",
      remote_id = "server_id",
      account = "email_account",
      metadata = { subject, to, from, cc, bcc },
      modified = true/false,
      synced = true/false,
      state = "NEW/MODIFIED/SYNCED",
      -- ... other draft data
    }
  },
  
  -- Metadata about draft system
  metadata = {
    total_count = 0,
    last_sync = timestamp,
    sync_in_progress = false,
  },
  
  -- Recovery information
  recovery = {
    unsaved_buffers = {
      ["buffer_id"] = {
        local_id = "draft_id",
        subject = "Draft Subject",
        timestamp = when_marked_unsaved
      }
    },
    last_recovery = timestamp,
    pending_syncs = [
      { local_id, account, subject }
    ]
  }
}
```

## API Functions

### Draft Management

#### `state.get_draft_by_buffer(buffer_id)`
Get draft data by buffer ID.

**Parameters:**
- `buffer_id` (number): The buffer ID to look up

**Returns:**
- `table|nil`: The draft data or nil if not found

**Example:**
```lua
local draft = state.get_draft_by_buffer(vim.api.nvim_get_current_buf())
if draft then
  print("Draft subject: " .. draft.metadata.subject)
end
```

#### `state.set_draft(buffer_id, draft_data)`
Store draft data for a buffer and update metadata.

**Parameters:**
- `buffer_id` (number): The buffer ID to associate with the draft
- `draft_data` (table): The draft data containing:
  - `local_id` (string): Unique local identifier
  - `remote_id` (string|nil): Remote server ID (if synced)
  - `account` (string): Email account name
  - `metadata` (table): Subject, to, from, etc.
  - `modified` (boolean): Whether draft has unsaved changes
  - `synced` (boolean): Whether draft is synced with server

**Example:**
```lua
state.set_draft(buf, {
  local_id = "draft_123",
  account = "personal",
  metadata = { subject = "Meeting Notes" },
  modified = true,
  synced = false
})
```

#### `state.remove_draft(buffer_id)`
Remove draft data from state and update count.

**Parameters:**
- `buffer_id` (number): The buffer ID of the draft to remove

**Example:**
```lua
state.remove_draft(buf)
```

#### `state.get_draft_count()`
Get total number of active drafts.

**Returns:**
- `number`: The number of drafts in state

**Example:**
```lua
local count = state.get_draft_count()
print(string.format("You have %d active drafts", count))
```

#### `state.get_all_drafts()`
Get all active drafts from state.

**Returns:**
- `table`: Map of buffer_id -> draft_data

**Example:**
```lua
local all_drafts = state.get_all_drafts()
for buf_id, draft in pairs(all_drafts) do
  print(buf_id .. ": " .. draft.metadata.subject)
end
```

### Sync Management

#### `state.is_draft_syncing()`
Check if any draft sync operation is in progress.

**Returns:**
- `boolean`: True if sync is in progress

**Example:**
```lua
if state.is_draft_syncing() then
  print("Sync in progress, please wait...")
end
```

#### `state.set_draft_sync_status(in_progress)`
Update draft sync status and timestamp.

**Parameters:**
- `in_progress` (boolean): Whether sync is in progress

**Example:**
```lua
-- Start sync
state.set_draft_sync_status(true)

-- After sync completes
state.set_draft_sync_status(false)
```

### Recovery Management

#### `state.get_unsaved_drafts()`
Get all drafts with unsaved changes.

**Returns:**
- `table`: Map of buffer_id -> draft_info for unsaved drafts

**Example:**
```lua
local unsaved = state.get_unsaved_drafts()
for buf_id, info in pairs(unsaved) do
  print("Unsaved: " .. info.subject)
end
```

#### `state.add_unsaved_draft(buffer_id, draft_info)`
Track a draft with unsaved changes for recovery.

**Parameters:**
- `buffer_id` (number): The buffer ID with unsaved changes
- `draft_info` (table): Basic info about the draft:
  - `local_id` (string): Draft identifier
  - `subject` (string): Draft subject line
  - `timestamp` (number): When marked as unsaved

**Example:**
```lua
state.add_unsaved_draft(buf, {
  local_id = draft.local_id,
  subject = draft.metadata.subject,
  timestamp = os.time()
})
```

#### `state.remove_unsaved_draft(buffer_id)`
Remove draft from unsaved tracking (after successful sync).

**Parameters:**
- `buffer_id` (number): The buffer ID to remove from tracking

**Example:**
```lua
-- After successful sync
state.remove_unsaved_draft(buf)
```

#### `state.get_pending_syncs()`
Get queue of drafts waiting to be synced.

**Returns:**
- `table`: Array of draft info waiting for sync

**Example:**
```lua
local pending = state.get_pending_syncs()
print(#pending .. " drafts waiting to sync")
```

#### `state.add_pending_sync(draft_info)`
Add draft to sync queue for batch processing.

**Parameters:**
- `draft_info` (table): Draft information to queue:
  - `local_id` (string): Draft identifier
  - `account` (string): Email account
  - `subject` (string): Draft subject

**Example:**
```lua
state.add_pending_sync({
  local_id = draft.local_id,
  account = draft.account,
  subject = draft.metadata.subject
})
```

#### `state.clear_pending_syncs()`
Clear all pending sync operations.

**Example:**
```lua
-- After processing all syncs
state.clear_pending_syncs()
```

#### `state.set_last_recovery()`
Update last recovery timestamp.

**Example:**
```lua
-- After recovery process
state.set_last_recovery()
```

## Draft Manager Integration

The `draft_manager_v2` module has been updated to use centralized state:

### Key Changes

1. **State Synchronization on Startup**
   ```lua
   -- In setup()
   M._sync_with_state()
   ```

2. **Draft Creation**
   ```lua
   -- Drafts are now stored in centralized state
   state.set_draft(buffer, draft)
   ```

3. **State Fallback**
   ```lua
   -- get_by_buffer() now checks state if not in local cache
   local draft = M.drafts[buffer] or state.get_draft_by_buffer(buffer)
   ```

4. **Unsaved Tracking**
   ```lua
   -- save_local() now tracks unsaved drafts
   state.add_unsaved_draft(buffer, {
     local_id = draft.local_id,
     subject = draft.metadata.subject,
     timestamp = os.time()
   })
   ```

## Usage Examples

### Check Draft Status
```lua
local function check_draft_status()
  local count = state.get_draft_count()
  local unsaved = vim.tbl_count(state.get_unsaved_drafts())
  local syncing = state.is_draft_syncing()
  
  print(string.format(
    "Drafts: %d total, %d unsaved%s",
    count,
    unsaved,
    syncing and " (syncing...)" or ""
  ))
end
```

### Recover Unsaved Drafts
```lua
local function recover_unsaved_drafts()
  local unsaved = state.get_unsaved_drafts()
  
  for buf_id, info in pairs(unsaved) do
    print(string.format(
      "Recovering draft: %s (last modified %d seconds ago)",
      info.subject,
      os.time() - info.timestamp
    ))
    -- Recovery logic here
  end
  
  state.set_last_recovery()
end
```

### Monitor Sync Progress
```lua
-- Start sync
state.set_draft_sync_status(true)

-- Check periodically
vim.defer_fn(function()
  if state.is_draft_syncing() then
    print("Still syncing...")
  else
    print("Sync complete!")
  end
end, 1000)
```

## Testing

Use the test suite to verify state integration:
```vim
:lua dofile('lua/neotex/plugins/tools/himalaya/scripts/features/test_draft_state_integration.lua')
```

All 8 tests should pass, covering:
- Draft creation and state tracking
- Save operations and modification tracking
- Sync status management
- Draft deletion and cleanup
- Unsaved draft recovery tracking
- Pending sync queue management
- State fallback mechanisms