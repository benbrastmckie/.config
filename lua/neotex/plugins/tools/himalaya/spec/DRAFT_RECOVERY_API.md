# Draft Recovery API Documentation (Phase 2)

This document describes the draft persistence and recovery functionality implemented in Phase 2 of the Draft Integration.

## Overview

The draft recovery system enables drafts to persist across Neovim sessions. When you restart Neovim, any drafts that were saved locally are automatically recovered and made available for editing.

## Key Features

- **Automatic Recovery**: Drafts are recovered automatically on Himalaya startup
- **Metadata Persistence**: Draft subjects, recipients, and status are preserved
- **Content Preservation**: Full draft content is recovered from local storage
- **Recovery Tracking**: System tracks which drafts need syncing after recovery
- **Manual Recovery**: Commands to manually trigger recovery and browse recovered drafts

## How It Works

### 1. State Persistence

When Neovim exits or state is saved:
- Draft metadata is persisted to `~/.local/share/nvim/himalaya/state.json`
- Includes: local_id, subject, recipients, sync status, file paths
- Full content remains in local storage files

### 2. Automatic Recovery

On Himalaya startup:
```lua
-- In init.lua, after draft_manager setup
vim.defer_fn(function()
  draft_manager.recover_session()
end, 100)
```

The recovery process:
1. Loads saved draft metadata from state
2. Checks if local storage files exist
3. Reloads draft content and metadata
4. Marks drafts as "recovered" (not yet opened)
5. Tracks unsaved drafts for later sync

### 3. Opening Recovered Drafts

Recovered drafts are not immediately opened in buffers. Instead:
- They're loaded into memory with a `recovered = true` flag
- Use commands or API to open them when needed
- Once opened, they behave like normal drafts

## API Functions

### `draft_manager.recover_session()`

Recovers all drafts from the previous session.

**Returns:**
- `number`: Count of successfully recovered drafts

**Example:**
```lua
local recovered = draft_manager.recover_session()
print(string.format("Recovered %d drafts", recovered))
```

**Behavior:**
- Reads draft metadata from persisted state
- Attempts to load each draft from local storage
- Removes stale entries (missing files)
- Emits `DRAFT_RECOVERED` events
- Tracks drafts needing sync

### `draft_manager.get_recovered_drafts()`

Gets list of drafts that were recovered but not yet opened.

**Returns:**
- `table`: Array of recovered draft info, sorted by modification time

**Example:**
```lua
local drafts = draft_manager.get_recovered_drafts()
for i, draft in ipairs(drafts) do
  print(i .. ". " .. draft.subject)
end
```

**Draft Info Structure:**
```lua
{
  local_id = "draft_123",
  subject = "Meeting Notes",
  to = "team@example.com",
  modified = true,
  synced = false,
  created_at = timestamp,
  modified_at = timestamp
}
```

### `draft_manager.open_recovered_draft(local_id)`

Opens a recovered draft in a new buffer.

**Parameters:**
- `local_id` (string): The draft's local identifier

**Returns:**
- `number|nil`: Buffer number if successful, nil otherwise

**Example:**
```lua
local buf = draft_manager.open_recovered_draft("draft_123")
if buf then
  vim.api.nvim_set_current_buf(buf)
end
```

**Behavior:**
- Creates new buffer with draft content
- Associates draft with buffer
- Clears `recovered` flag
- Sets up buffer autocmds
- Updates state tracking

### `draft_manager._load_draft_from_file(local_path)`

Internal function to load draft data from storage.

**Parameters:**
- `local_path` (string): Path to the draft file

**Returns:**
- `table|nil`: Draft object or nil if loading fails

## Commands

### `:HimalayaRecoverDrafts`

Manually trigger draft recovery (useful if automatic recovery was skipped).

**Example:**
```vim
:HimalayaRecoverDrafts
" Output: Recovered 3 draft(s) from previous session
```

### `:HimalayaListRecoveredDrafts`

Display a floating window with all recovered drafts.

**Example:**
```vim
:HimalayaListRecoveredDrafts
```

**Output:**
```
# Recovered Drafts

Found 2 recovered draft(s):

1. Weekly Status Report
   To: manager@company.com
   Modified: 2024-01-15 14:30
   Status: Unsaved

2. Project Proposal
   To: team@company.com
   Modified: 2024-01-15 10:15
   Status: Synced

Use :HimalayaOpenRecoveredDraft <id> to open a draft
```

### `:HimalayaOpenRecoveredDraft <index>`

Open a specific recovered draft by its index from the list.

**Parameters:**
- `index`: Number from the recovered drafts list (1-based)

**Example:**
```vim
:HimalayaOpenRecoveredDraft 1
" Opens "Weekly Status Report" in current window
```

## Recovery Scenarios

### Scenario 1: Clean Exit and Restart

1. User creates/edits drafts
2. User exits Neovim normally
3. State is saved automatically
4. User restarts Neovim
5. Drafts are recovered automatically
6. User can list and open recovered drafts

### Scenario 2: Crash Recovery

1. User creates/edits drafts
2. Neovim crashes or is killed
3. State may be partially saved (auto-save every 5 minutes)
4. User restarts Neovim
5. Drafts saved to local storage are recovered
6. Recent changes might be lost if not auto-saved

### Scenario 3: Unsaved Draft Tracking

1. User creates draft but doesn't sync to server
2. User exits Neovim
3. On restart, draft is recovered
4. System adds draft to pending sync queue
5. User is notified of unsaved drafts

## Integration with State Management

The recovery system integrates with centralized state:

```lua
-- State structure for recovery
draft = {
  metadata = {
    last_sync = timestamp,
    sync_in_progress = false,
  },
  recovery = {
    unsaved_buffers = {}, -- Tracks drafts needing sync
    last_recovery = timestamp,
    pending_syncs = [], -- Queue for batch sync
  }
}
```

## Error Handling

The recovery system handles various error conditions:

1. **Missing Files**: Drafts with missing storage files are removed from state
2. **Corrupted Data**: Failed loads are logged and skipped
3. **Invalid State**: Malformed metadata is ignored
4. **Storage Errors**: Recovery continues even if some drafts fail

## Events

Recovery emits events for integration:

- `DRAFT_RECOVERED`: Emitted for each successfully recovered draft
  ```lua
  {
    draft = draft_object,
    was_modified = true/false
  }
  ```

## Best Practices

1. **Regular Saves**: Save drafts frequently to ensure recoverability
2. **Sync Important Drafts**: Sync to server for additional backup
3. **Check Recovery**: Use `:HimalayaListRecoveredDrafts` after restart
4. **Clean Old Drafts**: Delete drafts you no longer need

## Testing

Run the recovery test suite:
```vim
:lua dofile('lua/neotex/plugins/tools/himalaya/scripts/features/test_draft_recovery.lua')
```

Manual testing:
```vim
:lua dofile('lua/neotex/plugins/tools/himalaya/scripts/test_recovery_manual.lua')
```

## Troubleshooting

### Drafts Not Recovering

1. Check state file exists:
   ```bash
   ls ~/.local/share/nvim/himalaya/state.json
   ```

2. Check local storage:
   ```bash
   ls ~/.local/share/nvim/himalaya/drafts/
   ```

3. Enable debug logging:
   ```vim
   :HimalayaDebug enable
   :HimalayaRecoverDrafts
   ```

### Recovery Performance

- Recovery is deferred 100ms after startup to avoid blocking
- Large numbers of drafts may take longer to recover
- Consider cleaning old drafts periodically

## Future Enhancements

- Conflict resolution for drafts modified on multiple machines
- Selective recovery (recover only specific accounts)
- Recovery progress indicator for many drafts
- Automatic cleanup of old recovered drafts