# Draft System v2 Documentation

## Overview

The new draft system (v2) provides a robust, local-first approach to email draft management with automatic synchronization to remote servers. This system replaces the previous fragmented implementation with a unified architecture.

## Key Features

- **Local-first storage**: All drafts are saved locally in JSON format
- **Automatic sync**: Background synchronization with retry logic
- **Live status indicators**: Visual feedback for draft state throughout the UI
- **Zero data loss**: Local persistence ensures drafts survive crashes
- **Performance optimized**: Fast operations even with many drafts

## Architecture

### Core Components

1. **draft_manager_v2.lua** - Central draft state management
   - Single source of truth for all draft state
   - Manages draft lifecycle (create, save, sync, delete)
   - Tracks drafts by buffer number

2. **local_storage.lua** - Persistent local storage
   - JSON-based storage with index
   - Atomic writes to prevent corruption
   - Fast lookups by local or remote ID

3. **sync_engine.lua** - Background synchronization
   - Queue-based async processing
   - Exponential backoff retry logic
   - Error recovery and notification

4. **draft_notifications.lua** - User feedback
   - Integrated with notification system
   - Debug-mode aware (verbose when <leader>ad is on)
   - Categorized notifications (user action vs background)

### UI Components

1. **email_composer_v2.lua** - Enhanced email composition
   - Autosave every 30 seconds
   - Immediate save on creation
   - Draft state tracking

2. **sidebar_v2.lua** - Draft list with sync status
   - Icons show draft state: 📝 new, 🔄 syncing, ✅ synced, ❌ error
   - Real-time updates as drafts sync

3. **email_preview_v2.lua** - Draft preview
   - Shows sync status in header
   - Loads from local storage for active drafts

4. **compose_status.lua** - Statusline for compose buffers
   - Shows draft state, remote ID, last sync time
   - Live sync queue status

## Draft States

Drafts progress through these states:

- **NEW** - Created locally, not yet synced
- **SYNCING** - Currently being synchronized
- **SYNCED** - Successfully synchronized with remote
- **ERROR** - Sync failed, will retry

## Usage

### Creating a Draft

```lua
-- Automatically handled when composing new email
:HimalayaCompose
```

### Draft Autosave

Drafts are automatically saved:
- Every 30 seconds while editing
- Immediately on creation
- On manual save (Ctrl+S in compose buffer)

### Migration from Old System

For users with existing drafts:

```vim
" Preview what will be migrated (dry run)
:HimalayaMigrateDrafts!

" Perform actual migration
:HimalayaMigrateDrafts

" Verify migration results
:HimalayaVerifyMigration
```

## Configuration

Add to your Himalaya setup:

```lua
require('neotex.plugins.tools.himalaya').setup({
  compose = {
    auto_save_interval = 30,  -- seconds
    delete_draft_on_send = true,
    use_tab = true,
  },
  sync = {
    interval = 5000,      -- milliseconds
    max_retries = 3,
    retry_delay = 2000,   -- milliseconds
  }
})
```

## Troubleshooting

### Draft not syncing?

1. Check sync status in sidebar (look for sync icon)
2. Enable debug mode with `<leader>ad` for detailed notifications
3. Check `:messages` for error details

### Lost draft?

Drafts are stored locally at:
```
~/.local/share/nvim/himalaya/drafts/
```

Even if sync fails, your draft content is safe locally.

### Performance issues?

The system is optimized for hundreds of drafts. If experiencing issues:
1. Check draft count with `:HimalayaVerifyMigration`
2. Clear old drafts from the Drafts folder
3. Increase sync interval in configuration

## Technical Details

### Storage Format

Drafts are stored as JSON files:

```json
{
  "local_id": "draft_20240710_123456_xxx",
  "remote_id": "123",
  "account": "personal",
  "metadata": {
    "subject": "Draft Subject",
    "to": "recipient@example.com",
    "from": "sender@example.com",
    "cc": "",
    "bcc": ""
  },
  "content": "Email body content...",
  "created_at": 1234567890,
  "updated_at": 1234567890,
  "state": "synced",
  "last_sync": 1234567890
}
```

### Buffer Variables

Each compose buffer has an associated draft tracked via:
```lua
vim.b.himalaya_draft = {
  local_id = "...",
  state = "synced",
  -- ... other fields
}
```

### Event System

The draft system integrates with the event bus:
- `DRAFT_CREATED` - New draft created
- `DRAFT_SAVED` - Draft saved locally
- `DRAFT_SYNCED` - Draft synced to remote
- `DRAFT_SYNC_FAILED` - Sync failure (will retry)

## Development

### Testing

Run the test suites:

```vim
" Unit tests for each phase
:lua require('neotex.plugins.tools.himalaya.spec.test_draft_foundation').run_all_tests()
:lua require('neotex.plugins.tools.himalaya.spec.test_draft_composer').run_all_tests()
:lua require('neotex.plugins.tools.himalaya.spec.test_draft_ui').run_all_tests()

" Integration tests
:lua require('neotex.plugins.tools.himalaya.spec.test_draft_integration').run_all_tests()
```

### Adding Features

When extending the draft system:

1. Update draft_manager_v2 for state changes
2. Add UI feedback via draft_notifications
3. Ensure local_storage handles new data
4. Add tests for new functionality

## Migration Guide

For developers migrating from the old system:

### Old System Issues
- Multiple caches (draft_cache, local_draft_cache, draft_sync)
- Synchronous operations blocking UI
- No unified state management
- Complex error handling

### New System Benefits
- Single source of truth (draft_manager_v2)
- Async operations with sync_engine
- Robust local persistence
- Clear error states and recovery

### API Changes

Old:
```lua
draft_cache.save_draft(account, folder, draft)
draft_sync.sync_draft(draft_id)
```

New:
```lua
draft_manager.create(buffer, account, metadata)
draft_manager.save_local(buffer)
draft_manager.sync_remote(buffer)
```

## Future Enhancements

Planned improvements:
- Conflict resolution for concurrent edits
- Batch sync operations
- Compression for large drafts
- Encryption for sensitive content