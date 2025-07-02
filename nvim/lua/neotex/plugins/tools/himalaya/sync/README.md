# Synchronization System

Email synchronization modules providing unified sync management, mbsync integration, OAuth handling, and process coordination.

## Purpose

The sync layer handles all email synchronization operations:
- Unified sync management with progress tracking
- Integration with external tools (mbsync, Himalaya CLI)
- OAuth2 token lifecycle management  
- Process coordination and conflict prevention

## Modules

### manager.lua
Unified synchronization manager that coordinates all sync operations:
- Manages sync lifecycle (start, progress, completion)
- Provides unified sync state tracking across different sync types
- Handles sync progress updates and status notifications
- Coordinates with UI layer for real-time status updates

Key functions:
- `start_sync(type, options)` - Begin a sync operation
- `update_progress(progress)` - Update sync progress state
- `complete_sync(type, result)` - Mark sync as complete
- `get_sync_info()` - Get current sync status and progress
- `notify_ui_update()` - Notify UI components of sync changes

<!-- TODO: Add sync queue for managing multiple sync requests -->
<!-- TODO: Implement sync retry logic with exponential backoff -->

### mbsync.lua
Integration with mbsync for full email synchronization:
- Executes mbsync commands with progress parsing
- Handles different sync strategies (inbox-only, full-sync)
- Manages sync cancellation and cleanup
- Provides real-time progress updates to manager

Key functions:
- `sync_inbox(account)` - Sync only inbox folder
- `sync_full(account)` - Full synchronization of all folders
- `cancel_sync()` - Cancel running sync operation
- `get_status()` - Get current mbsync status
- `parse_progress_line(line)` - Parse mbsync output for progress

<!-- TODO: Add support for selective folder synchronization -->
<!-- TODO: Implement bandwidth throttling for slow connections -->

### oauth.lua
OAuth2 token management for Gmail and other providers:
- Automatic token refresh with expiration handling
- Secure token storage and retrieval
- Integration with external OAuth refresh scripts
- Error handling for authentication failures

Key functions:
- `get_valid_token(account)` - Get valid token, refreshing if needed
- `refresh_token(account)` - Force token refresh
- `store_token(account, token)` - Securely store token
- `clear_token(account)` - Remove stored token

<!-- TODO: Add support for multiple OAuth providers -->
<!-- TODO: Implement token encryption for security -->

### lock.lua
Process locking system to prevent concurrent operations:
- File-based locking using flock for cross-process coordination
- Timeout handling to prevent deadlocks
- Automatic cleanup of stale locks
- Support for multiple named locks

Key functions:
- `acquire_lock(name, timeout)` - Acquire named lock with timeout
- `release_lock(name)` - Release named lock
- `with_lock(name, fn, timeout)` - Execute function with lock held
- `cleanup_stale_locks()` - Remove locks from dead processes

<!-- TODO: Add lock monitoring and debugging utilities -->
<!-- TODO: Consider implementing advisory locks for performance -->

## Architecture Notes

The sync layer follows these principles:
- **Unified coordination** - Single manager coordinates all sync types
- **Progress transparency** - Real-time progress updates for long operations
- **Conflict prevention** - Locking prevents concurrent operations
- **Error resilience** - Graceful handling of network and authentication errors

## Error Handling

The sync system handles these error scenarios:
- Network connectivity issues during sync
- OAuth token expiration and refresh failures
- mbsync process crashes or hangs
- Concurrent sync attempts
- UIDVALIDITY changes requiring maildir reset

## Usage Examples

```lua
-- Unified sync manager
local manager = require("neotex.plugins.tools.himalaya.sync.manager")

-- Start full sync with progress tracking
manager.start_sync('full', { account = 'gmail' })

-- Get current sync status
local sync_info = manager.get_sync_info()
print("Sync type:", sync_info.type)
print("Status:", sync_info.status)
print("Progress:", sync_info.progress)

-- Direct mbsync operations
local mbsync = require("neotex.plugins.tools.himalaya.sync.mbsync")
mbsync.sync_inbox('gmail')

-- OAuth token management
local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
local token = oauth.get_valid_token('gmail')

-- Process locking
local lock = require("neotex.plugins.tools.himalaya.sync.lock")
lock.with_lock('sync_gmail', function()
  -- Critical section - only one process can sync gmail
  mbsync.sync_full('gmail')
end, 30) -- 30 second timeout
```

## Navigation
- [← Himalaya Plugin](../README.md)