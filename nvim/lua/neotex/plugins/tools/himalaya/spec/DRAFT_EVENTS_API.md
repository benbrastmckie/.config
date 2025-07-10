# Draft Event System API Documentation (Phase 3)

This document describes the event system integration for the draft system implemented in Phase 3.

## Overview

The draft system now emits events for all major operations, enabling:
- Reactive UI updates without tight coupling
- Better debugging through event logging
- Future extensibility for features like conflict resolution
- Consistent patterns with the rest of Himalaya

## Event Types

### Draft Lifecycle Events

#### `DRAFT_CREATED`
Emitted when a new draft is created.

```lua
{
  draft_id = "local_id",
  buffer = buffer_number,
  account = "account_name",
  metadata = { subject, to, from, cc, bcc },
  compose_type = "new|reply|forward"
}
```

#### `DRAFT_SAVED`
Emitted when a draft is saved locally.

```lua
{
  draft_id = "local_id",
  buffer = buffer_number,
  is_autosave = false,
  content_length = 1234
}
```

#### `DRAFT_DELETED`
Emitted when a draft is deleted.

```lua
{
  draft_id = "local_id",
  remote_id = "remote_id",
  account = "account_name"
}
```

#### `DRAFT_BUFFER_OPENED`
Emitted when a draft buffer is opened.

```lua
{
  draft_id = "local_id",
  buffer = buffer_number
}
```

#### `DRAFT_BUFFER_CLOSED`
Emitted when a draft buffer is closed.

```lua
{
  draft_id = "local_id",
  buffer = buffer_number,
  was_saved = true
}
```

### Draft Sync Events

#### `DRAFT_SYNC_QUEUED`
Emitted when a draft is queued for synchronization.

```lua
{
  draft_id = "local_id",
  account = "account_name",
  has_remote_id = false
}
```

#### `DRAFT_SYNC_STARTED`
Emitted when sync begins (first attempt only).

```lua
{
  draft_id = "local_id",
  account = "account_name"
}
```

#### `DRAFT_SYNC_PROGRESS`
Emitted on each sync attempt.

```lua
{
  draft_id = "local_id",
  attempt = 1,
  max_retries = 3
}
```

#### `DRAFT_SYNCED`
Emitted when sync succeeds.

```lua
{
  draft_id = "local_id",
  remote_id = "remote_id",
  sync_time = timestamp
}
```

#### `DRAFT_SYNC_FAILED`
Emitted when sync fails.

```lua
{
  draft_id = "local_id",
  error = "error_message",
  will_retry = true
}
```

#### `DRAFT_SYNC_COMPLETED`
Emitted when sync completes (success or final failure).

```lua
{
  draft_id = "local_id",
  duration = seconds,
  queue_remaining = 0
}
```

### Draft Autosave Events

#### `DRAFT_AUTOSAVE_TRIGGERED`
Emitted when autosave starts.

```lua
{
  draft_id = "local_id",
  trigger = "timer|change"
}
```

#### `DRAFT_AUTOSAVE_COMPLETED`
Emitted when autosave completes successfully.

```lua
{
  draft_id = "local_id",
  duration = milliseconds
}
```

#### `DRAFT_AUTOSAVE_FAILED`
Emitted when autosave fails.

```lua
{
  draft_id = "local_id",
  error = "error_message"
}
```

### Draft Recovery Events

#### `DRAFT_RECOVERED`
Emitted for each draft recovered from previous session.

```lua
{
  draft = draft_object,
  was_modified = true
}
```

#### `DRAFT_RECOVERY_NEEDED`
Emitted when orphaned draft is found that needs recovery.

```lua
{
  draft_id = "local_id",
  last_modified = timestamp,
  metadata = { subject, to, from }
}
```

#### `DRAFT_RECOVERY_COMPLETED`
Emitted when recovery process completes.

```lua
{
  recovered = 5,
  failed = 1
}
```

#### `DRAFT_RECOVERY_FAILED`
Emitted when recovery fails for a draft.

```lua
{
  draft_id = "local_id",
  error = "error_message"
}
```

### Draft Conflict Events

#### `DRAFT_CONFLICT_DETECTED`
Emitted when local/remote conflict is detected.

```lua
{
  draft_id = "local_id",
  local_version = "hash",
  remote_version = "hash"
}
```

#### `DRAFT_CONFLICT_RESOLVED`
Emitted when conflict is resolved.

```lua
{
  draft_id = "local_id",
  resolution = "local|remote|merged"
}
```

## Subscribing to Events

### Basic Subscription

```lua
local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_types = require('neotex.plugins.tools.himalaya.core.events')

events_bus.on(event_types.DRAFT_SAVED, function(data)
  print("Draft saved:", data.draft_id)
end)
```

### Subscription with Options

```lua
events_bus.on(event_types.DRAFT_SYNCED, function(data)
  -- Handle event
end, {
  priority = 100,    -- Higher priority runs first
  module = "my_module"  -- For debugging
})
```

### Multiple Event Subscription

```lua
local update_events = {
  event_types.DRAFT_SAVED,
  event_types.DRAFT_SYNCED,
  event_types.DRAFT_SYNC_FAILED
}

for _, event in ipairs(update_events) do
  events_bus.on(event, function(data)
    -- Update UI
  end)
end
```

## UI Integration

### Sidebar Updates

The sidebar subscribes to draft events for real-time updates:

```lua
-- Refresh list when draft is created
events_bus.on(event_types.DRAFT_CREATED, function(data)
  if sidebar.is_open() and is_drafts_folder() then
    vim.schedule(function()
      email_list.refresh_email_list()
    end)
  end
end)
```

### Statusline Updates

The compose status module subscribes to sync events:

```lua
events_bus.on(event_types.DRAFT_SYNC_PROGRESS, function(data)
  local draft = draft_manager.get_by_local_id(data.draft_id)
  if draft and vim.api.nvim_buf_is_valid(draft.buffer) then
    vim.schedule(function()
      vim.api.nvim_buf_call(draft.buffer, function()
        vim.cmd('redrawstatus')
      end)
    end)
  end
end)
```

## Event-Driven Features

### Auto-Recovery Detection

On startup, the system checks for orphaned drafts:

```lua
function M._check_orphaned_drafts()
  -- Find drafts in storage but not in state
  for _, stored in ipairs(stored_drafts) do
    if not state_ids[stored.local_id] then
      events_bus.emit(event_types.DRAFT_RECOVERY_NEEDED, {
        draft_id = stored.local_id,
        last_modified = stored.updated_at,
        metadata = stored.metadata
      })
    end
  end
end
```

### Progress Notifications

Draft notifications module subscribes to provide user feedback:

```lua
events_bus.on(event_types.DRAFT_SYNC_PROGRESS, function(data)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(
      string.format("Syncing draft (attempt %d/%d)", 
        data.attempt, data.max_retries),
      notify.categories.BACKGROUND
    )
  end
end)
```

## Event Logging

Events are automatically logged in debug mode:

```lua
-- In orchestration/integration.lua
local draft_events = {
  event_constants.DRAFT_CREATED,
  event_constants.DRAFT_SAVED,
  event_constants.DRAFT_DELETED,
  event_constants.DRAFT_SYNCED,
  event_constants.DRAFT_SYNC_FAILED,
}

for _, event_name in ipairs(draft_events) do
  events.on(event_name, function(data)
    logger.debug(string.format("Draft Event: %s", event_name), data)
  end, {
    priority = 10,
    module = "draft_event_logger"
  })
end
```

## Testing Events

### Capturing Events in Tests

```lua
local captured = {}

events_bus.on(event_types.DRAFT_CREATED, function(data)
  table.insert(captured, data)
end)

-- Perform action
draft_manager.create(buf, 'test_account')

-- Check event was emitted
assert(#captured == 1)
assert(captured[1].draft_id ~= nil)
```

### Running Event Tests

```vim
:lua dofile('lua/neotex/plugins/tools/himalaya/scripts/features/test_draft_events.lua')
```

## Best Practices

1. **Always emit events for user-facing operations**
   - Draft creation, saving, deletion
   - Sync start/completion
   - Recovery operations

2. **Use appropriate event granularity**
   - Don't emit events for internal state changes
   - Batch related operations when possible

3. **Include relevant context in event data**
   - IDs for correlation
   - Timestamps for ordering
   - Status information

4. **Handle events asynchronously**
   - Use `vim.schedule()` for UI updates
   - Don't block event emission

5. **Clean up subscriptions**
   - Remove handlers when components are destroyed
   - Use weak references where appropriate

## Future Extensions

The event system enables future features:

1. **Conflict Resolution UI**
   - Listen for `DRAFT_CONFLICT_DETECTED`
   - Show merge dialog
   - Emit `DRAFT_CONFLICT_RESOLVED`

2. **Draft Analytics**
   - Track draft lifecycle
   - Measure sync performance
   - Identify problem drafts

3. **Multi-Device Sync**
   - Track device-specific changes
   - Coordinate sync across devices
   - Handle merge conflicts

4. **Undo/Redo System**
   - Track draft modifications
   - Build operation history
   - Enable reverting changes