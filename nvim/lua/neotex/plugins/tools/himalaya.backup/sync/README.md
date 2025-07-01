# Synchronization System

Email synchronization modules for the Himalaya plugin.

## Modules

### manager.lua
Orchestrates synchronization operations:
- Manages sync strategies (full sync vs quick check)
- Coordinates between mbsync and himalaya commands
- Handles sync scheduling and status updates

Key functions:
- `sync(account, opts)` - Perform email synchronization
- `check_new(account)` - Quick check for new emails
- `get_status()` - Get current sync status

### mbsync.lua
Integration with mbsync for full email synchronization:
- Executes mbsync commands
- Parses progress output
- Handles error conditions
- Updates UI with sync progress

Key functions:
- `sync(account, callback)` - Run mbsync for account
- `parse_progress(line)` - Parse mbsync output
- `is_running()` - Check if sync is in progress

### oauth.lua
OAuth2 token management:
- Token storage and retrieval
- Automatic token refresh
- Integration with OAuth scripts
- Token expiration handling

Key functions:
- `get_token(account)` - Retrieve valid OAuth token
- `refresh_token(account)` - Force token refresh
- `validate_token(token)` - Check token validity

### lock.lua
Process locking to prevent concurrent operations:
- Uses flock for process synchronization
- Prevents multiple sync operations
- Timeout handling

Key functions:
- `acquire(name)` - Acquire a named lock
- `release(name)` - Release a lock
- `with_lock(name, fn)` - Execute function with lock

## Usage Examples

```lua
-- Perform full sync
local manager = require("neotex.plugins.tools.himalaya.sync.manager")
manager.sync("personal", {
  on_complete = function() print("Sync complete") end
})

-- Check for new emails
manager.check_new("personal")

-- Get OAuth token
local oauth = require("neotex.plugins.tools.himalaya.sync.oauth")
local token = oauth.get_token("personal")
```

## Navigation
- [← Himalaya Plugin](../README.md)