# Streamlined Email Sync Solution

## Problem Analysis

The user reported:
1. OAuth authentication now working (via NixOS config fix) ✅
2. Email updates when opening/closing Himalaya (native Himalaya sync works) ✅
3. `<leader>ms` gives "Mail sync failed" (mbsync has issues) ❌
4. User wants automatic sidebar updates and streamlined mail sync ❌

## Root Cause

- `<leader>ms` was mapped to `:HimalayaSmartSync` which relies on mbsync
- mbsync has OAuth authentication issues despite working Himalaya CLI
- No automatic sidebar refresh when emails change
- User experience was not seamless

## Solution Implemented

### 1. Native Himalaya Sync Module (`native_sync.lua`)

**Purpose**: Replace mbsync-based sync with native Himalaya CLI operations

**Key Features**:
- Uses `utils.get_email_list()` to force server sync (clears cache first)
- Combines OAuth refresh with native Himalaya operations  
- Automatic sidebar refresh after sync operations
- Background sync timer that only runs when sidebar is open
- Smart sync status tracking

**How it works**:
```lua
-- Instead of running `mbsync -a`, we:
1. Clear email cache to force fresh server fetch
2. Call utils.get_email_list() which uses Himalaya CLI directly
3. This triggers server sync through Himalaya's native IMAP connection
4. Auto-refresh sidebar if open
```

### 2. Seamless Experience Module (`seamless_experience.lua`)

**Purpose**: Provide automatic sidebar updates and enhanced user experience

**Key Features**:
- Background email checking (60-second intervals)
- Only updates sidebar when actual changes detected
- Enhanced folder/account switching with auto-load
- Visual feedback for sync operations
- Smart refresh that preserves cursor position

**Background Updates**:
- Runs timer only when sidebar is open
- Compares email IDs to detect changes
- Updates sidebar content without full refresh
- Stops timer when sidebar closes

### 3. Updated Keybinding

Changed `<leader>ms` from `:HimalayaSmartSync` (mbsync-based) to `:HimalayaEnhancedSync` (native Himalaya)

## Benefits

### ✅ Fixes the sync problem
- `<leader>ms` now works because it uses working Himalaya CLI instead of broken mbsync
- OAuth tokens are properly utilized through Himalaya's native connection
- No more "Mail sync failed" errors

### ✅ Automatic sidebar updates  
- Sidebar refreshes automatically every 60 seconds when open
- Updates only when there are actual email changes
- Preserves user's cursor position and focus

### ✅ Seamless experience
- Background sync every 5 minutes (configurable)
- Visual feedback for sync operations
- Enhanced folder/account switching
- Smart refresh on all email operations (send, delete, move, etc.)

### ✅ Performance optimized
- Debounced refreshes prevent UI spam
- Cache-aware updates
- Background operations don't block UI
- Timer automatically stops when not needed

## Usage

### Basic Commands
- `<leader>ms` - Enhanced sync (replaces broken mbsync)
- `:HimalayaNativeSync` - Native Himalaya sync
- `:HimalayaAutoSyncToggle` - Toggle automatic background sync
- `:HimalayaSyncStatus` - Show sync status

### Automatic Features (Active by Default)
- **Auto-refresh**: Sidebar updates every 60 seconds when open
- **Auto-sync**: Background sync every 5 minutes when sidebar open  
- **Smart updates**: Only refresh when emails actually change
- **Visual feedback**: Sync success indicators in sidebar

### Enhanced Navigation
- `gm` - Enhanced folder switching with auto-load
- `ga` - Enhanced account switching with auto-load  
- `gs` - Quick sync in sidebar
- `gS` - Force sync in sidebar
- `gA` - Toggle auto-refresh in sidebar

## Technical Implementation

### How Email Updates Work on Open/Close
The original behavior (emails update when opening/closing Himalaya) works because:

1. `ui.show_email_list()` calls `utils.get_email_list()`
2. `utils.get_email_list()` calls `M.execute_himalaya({ 'envelope', 'list' })`
3. This executes: `himalaya envelope list -a account -f folder -o json`
4. Himalaya CLI connects to IMAP server and fetches fresh email list
5. This **IS** the sync - Himalaya natively syncs with server

### Why mbsync Fails But Himalaya Works
- **Himalaya**: Uses its own OAuth token management and IMAP connection
- **mbsync**: Separate OAuth configuration that conflicts with Himalaya's setup
- **Solution**: Use Himalaya's working connection instead of broken mbsync

### Automatic Sidebar Updates
The new system adds:
1. **Background timer**: Checks for email changes every 60 seconds
2. **Change detection**: Compares email IDs to detect new/removed emails  
3. **Smart updates**: Only refreshes UI when changes detected
4. **Event-driven**: Auto-refresh after email operations (send, delete, etc.)

## Configuration

Auto-sync and auto-refresh are enabled by default. To customize:

```lua
-- In config.lua
M.config = {
  auto_sync = true,              -- Enable background sync
  sync_interval = 300,           -- Sync every 5 minutes
}

-- In seamless_experience.lua  
M.auto_refresh_interval = 60    -- UI refresh every 60 seconds
```

## Result

✅ **`<leader>ms` now works** - Uses native Himalaya instead of broken mbsync
✅ **Automatic sidebar updates** - Background refresh every 60 seconds
✅ **Seamless experience** - Auto-sync, visual feedback, enhanced navigation  
✅ **Performance optimized** - Smart caching and debounced updates
✅ **OAuth compatible** - Works with existing OAuth setup

The user now has a fully working, automatically updating email experience that leverages the working Himalaya OAuth authentication instead of fighting with mbsync configuration issues.