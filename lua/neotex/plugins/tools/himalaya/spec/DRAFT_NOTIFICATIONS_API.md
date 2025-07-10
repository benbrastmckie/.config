# Draft Notification System API Documentation (Phase 4)

This document describes the notification system integration for the draft system implemented in Phase 4.

## Overview

The draft system now uses the unified notification system for all user-facing operations, providing:
- Consistent notification behavior across all draft operations
- Intelligent filtering based on debug mode and notification categories
- Context-aware messages with relevant metadata
- Proper categorization for different types of operations

## Notification Helper

### `notify_draft(message, category, context)`

A centralized helper function for all draft-related notifications.

```lua
local function notify_draft(message, category, context)
  context = vim.tbl_extend('force', context or {}, {
    module = 'himalaya',
    feature = 'drafts'
  })
  notify.himalaya(message, category, context)
end
```

**Parameters:**
- `message` (string): The notification message
- `category` (table): Notification category from `notify.categories`
- `context` (table?): Additional context information

## Notification Categories

### User Actions (Always Shown)
These notifications are always displayed to the user:

- **Draft Saved**: `notify.categories.USER_ACTION`
  - Message: "Draft saved: [subject]"
  - Context: `{ file, draft_id }`

- **Draft Deleted**: `notify.categories.USER_ACTION`
  - Message: "Draft deleted"
  - Context: `{ draft_id }`

- **Draft Synced**: `notify.categories.USER_ACTION`
  - Message: "Draft synced successfully"
  - Context: `{ draft_id, subject }`

- **Draft Recovered**: `notify.categories.USER_ACTION`
  - Message: "Recovered N draft(s) from previous session"
  - Context: `{ recovered, failed }`

- **Email Sent**: `notify.categories.USER_ACTION`
  - Message: "Email sent: [subject]"
  - Context: `{ to, subject }`

### Status Updates (Debug Mode Only)
These notifications are only shown when debug mode is enabled:

- **Draft Created**: `notify.categories.BACKGROUND`
  - Message: "New draft created"
  - Context: `{ local_id, buffer, account, compose_type }`

- **Draft Syncing**: `notify.categories.STATUS`
  - Message: "Syncing draft..."
  - Context: `{ allow_batching: true, draft_id }`

- **Buffer Closed**: `notify.categories.STATUS`
  - Message: "Draft buffer closed"
  - Context: `{ local_id, buffer }`

### Warnings (Always Shown)
Warning notifications for potential issues:

- **No Draft**: `notify.categories.WARNING`
  - Message: "No draft associated with this buffer"
  - When: Operations on non-draft buffers

- **Recovery Failed**: `notify.categories.WARNING`
  - Message: "Failed to recover N draft(s)"
  - Context: `{ failed }`

### Errors (Always Shown)
Error notifications for failures:

- **Save Failed**: `notify.categories.ERROR`
  - Message: "Failed to save draft: [error]"
  - Context: `{ draft_id }`

- **Sync Failed**: `notify.categories.ERROR`
  - Message: "Draft sync failed: [error]"
  - Context: `{ draft_id }`

- **Delete Failed**: `notify.categories.ERROR`
  - Message: "Failed to delete remote draft: [error]"
  - Context: `{ draft_id }`

## Usage Examples

### Basic Operations

```lua
-- Save draft with notification
function M.save(buffer)
  local draft = M.get_by_buffer(buffer)
  if not draft then
    notify_draft("No draft associated with this buffer", notify.categories.WARNING)
    return false
  end
  
  -- Save logic...
  
  notify_draft(
    string.format("Draft saved: %s", draft.metadata.subject or "Untitled"),
    notify.categories.USER_ACTION,
    { file = draft.local_path, draft_id = draft.local_id }
  )
  return true
end
```

### Async Operations

```lua
-- Sync with progress notifications
function M.sync_remote(buffer)
  -- Initial status notification
  notify_draft(
    "Syncing draft...",
    notify.categories.STATUS,
    { allow_batching = true, draft_id = draft.local_id }
  )
  
  -- Queue sync operation...
end

-- Handle sync completion
function M.handle_sync_completion(local_id, remote_id, success, error)
  if success then
    notify_draft(
      "Draft synced successfully",
      notify.categories.USER_ACTION,
      { draft_id = remote_id, subject = draft.metadata.subject }
    )
  else
    notify_draft(
      string.format("Draft sync failed: %s", error),
      notify.categories.ERROR,
      { draft_id = local_id }
    )
  end
end
```

### Recovery Operations

```lua
-- Notify recovery results
if recovered > 0 then
  notify_draft(
    string.format("Recovered %d draft(s) from previous session", recovered),
    notify.categories.USER_ACTION,
    { recovered = recovered, failed = failed }
  )
end
```

## Debug Mode Behavior

The notification system respects the global and module-specific debug settings:

1. **Normal Mode**: Only shows USER_ACTION, WARNING, and ERROR notifications
2. **Debug Mode**: Shows all notifications including STATUS and BACKGROUND

Toggle debug mode:
```vim
:NotifyDebug himalaya    " Toggle himalaya module debug mode
:NotifyDebug             " Toggle global debug mode
```

## Context Information

All draft notifications include standard context:
- `module`: Always set to 'himalaya'
- `feature`: Always set to 'drafts'
- Additional context specific to the operation

This enables:
- Filtering by module/feature
- Statistics tracking
- Batch processing for related notifications

## Integration with Commands

The command system has been updated to use the notification system:

```lua
-- Recovery command
if recovered == 0 then
  local notify = require('neotex.util.notifications')
  notify.himalaya("No drafts to recover", notify.categories.USER_ACTION)
end

-- Open recovered draft
notify.himalaya(
  string.format("Opened recovered draft: %s", draft.subject),
  notify.categories.USER_ACTION
)
```

## Testing Notifications

### Manual Testing
```vim
" Create and save a draft
:HimalayaDraftNew
" Type some content
:HimalayaDraftSave    " Should see "Draft saved: [subject]"

" Test error handling
:new
:HimalayaDraftSave    " Should see "No draft associated with this buffer"
```

### Debug Mode Testing
```vim
" Enable debug mode
:NotifyDebug himalaya

" Create draft - should see background notification
:HimalayaDraftNew

" Disable debug mode
:NotifyDebug himalaya
```

### Programmatic Testing
```lua
-- Run notification tests
dofile('lua/neotex/plugins/tools/himalaya/scripts/features/test_draft_notifications.lua')
_G.draft_notifications_test:run()
```

## Best Practices

1. **Use appropriate categories**:
   - USER_ACTION for user-initiated operations
   - STATUS for progress updates
   - BACKGROUND for automatic operations
   - WARNING for recoverable issues
   - ERROR for failures

2. **Include relevant context**:
   - Always include draft_id when available
   - Include subject for user-facing notifications
   - Add file paths for save operations

3. **Message clarity**:
   - Keep messages concise and actionable
   - Include specific error details for failures
   - Use consistent formatting

4. **Batching**:
   - Set `allow_batching = true` for rapid operations
   - Useful for sync progress notifications

## Migration Notes

All direct `vim.notify` calls have been replaced with the notification system:
- `vim.notify` → `notify.himalaya` or `notify_draft`
- Log levels mapped to categories
- Context added for better tracking