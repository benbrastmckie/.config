# Sync System Refactor Plan (Simplified)

## Goals
1. Prevent concurrent sync conflicts
2. Handle interruptions gracefully
3. Simple rejection of new requests when sync is running
4. Automatic OAuth refresh on authentication failures
5. Clear user feedback

## Design Principles

### 1. Single Sync at a Time
- Only ONE sync can run at a time globally
- New sync requests are rejected with clear notification
- User must wait or cancel current sync first

### 2. Simple State Tracking
```
IDLE -> RUNNING -> IDLE
     \-> FAILED -> IDLE
```

### 3. Conflict Prevention
- Check if sync is running before starting new one
- Provide clear feedback about what's running
- Suggest next actions (wait, cancel, or check status)

### 4. Automatic OAuth Handling
- Detect authentication failures (socket timeout, auth failed)
- Automatically refresh OAuth token
- Retry sync once after successful refresh

### 5. Unified Cleanup
- `<leader>mU` (HimalayaCleanup) kills all processes
- Clears all state and locks
- Simple and predictable

## Implementation Changes

### 1. Remove Queue System
- No queue needed - just reject new requests
- Simpler code, easier to debug
- Clear user expectations

### 2. Enhanced Conflict Detection
```lua
function M.sync_inbox(is_user_action)
  if M.is_sync_running_globally() then
    -- Reject with clear message
    notify.himalaya('Sync already running - please wait or cancel first')
    return false
  end
  -- Proceed with sync
end
```

### 3. OAuth Auto-Refresh
```lua
-- Detect these patterns:
- "Socket error.*timeout"
- "AUTHENTICATIONFAILED"
- No output (hung auth)
-- Then automatically refresh and retry
```

### 4. Simple Cleanup
```lua
function M.cleanup()
  -- Kill ALL sync processes
  -- Clear ALL state
  -- Remove ALL locks
  -- No special cases
end
```

## Benefits
1. **Simplicity** - No complex queue management
2. **Predictable** - Always know what will happen
3. **Clear feedback** - User knows exactly what's wrong
4. **Easy cleanup** - One command fixes everything
5. **Less bugs** - Simpler code has fewer edge cases