# Sync Status Display Issue Analysis

## Problem Statement
`<leader>mz` (fast check) does not display sync status in the sidebar header, while `<leader>ms` (sync inbox) correctly shows sync status immediately.

## Current Behavior

### What Works (`<leader>ms`)
1. User presses `<leader>ms`
2. Sets state:
   - `sync.status = '¿ Syncing...'`
   - `sync.start_time = os.time()`
   - `sync.running = true`
3. Calls `main.refresh_sidebar_header()`
4. Sidebar immediately shows: "¿ Syncing..."
5. Updates progress during sync
6. Clears status when complete

### What Doesn't Work (`<leader>mz`)
1. User presses `<leader>mz`
2. Currently sets state (same as above):
   - `sync.status = '¿ Checking for new mail...'`
   - `sync.start_time = os.time()`
   - `sync.running = true`
3. Calls `main.refresh_sidebar_header()`
4. **Sidebar does NOT show the checking status**
5. Only shows notifications in message area

## Code Flow Analysis

### Key Functions

1. **`init.lua` - HimalayaFastCheck command**
   - Sets sync state
   - Calls `main.refresh_sidebar_header()`
   - Starts async `mbsync.himalaya_fast_check()`

2. **`ui/main.lua` - refresh_sidebar_header()**
   - Gets sidebar buffer
   - Builds header lines including `get_sync_status_line()`
   - Calls `sidebar.update_header_lines()`

3. **`ui/main.lua` - get_sync_status_line_detailed()**
   - Checks `sync.checking` (originally, now uses `sync.running`)
   - Returns status string if syncing
   - Early return if no sync running

4. **`ui/sidebar.lua` - update_header_lines()**
   - Updates only header lines in buffer
   - Checks if lines actually changed before updating

## Potential Issues

### 1. Timing Issue
- State might be cleared before UI updates
- Async callback might fire too quickly

### 2. Buffer State Issue
- Sidebar buffer might not be properly initialized
- `himalaya_emails` might be required but not set

### 3. State Management Issue
- Different state variables for different operations
- State not persisting between function calls

### 4. Refresh Method Issue
- `refresh_sidebar_header()` vs `refresh_email_list()`
- Different refresh paths for different commands

## Debug Points Needed

1. **In HimalayaFastCheck**:
   - Confirm state is set before refresh
   - Check if sidebar buffer exists and is valid
   - Verify refresh is actually called

2. **In refresh_sidebar_header**:
   - Check if buffer is found
   - Verify get_sync_status_line is called
   - Confirm update_header_lines receives status

3. **In get_sync_status_line_detailed**:
   - Verify sync.running is true
   - Check what status string is returned
   - Ensure no early returns

4. **In update_header_lines**:
   - Check if header lines include sync status
   - Verify buffer is actually updated
