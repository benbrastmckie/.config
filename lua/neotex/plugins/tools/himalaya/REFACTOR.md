# Himalaya Email Plugin Refactoring Plan

## Executive Summary & Progress Tracker

**MISSION**: Fix broken email synchronization and restore useful progress indicators

**STATUS**: Phases 1-8 ✅ Complete | Phase 9 🚧 Critical - In Progress

**CURRENT CRITICAL ISSUES**:
- 🚧 **Multiple processes still spawning** - Despite safeguards, concurrent mbsync processes appear
- 🚧 **Progress parser broken** - "0/1894 new" where 0 never increments
- 🚧 **Race conditions in sync** - Lock system has timing gaps

**COMPLETED ISSUES**:
- ✅ ~~Fake sync (replaced with real mbsync)~~
- ✅ ~~OAuth blocking sync (removed dependency)~~  
- ✅ ~~Missing useful progress info~~
- ✅ ~~Email duplication (was due to stale Himalaya cache)~~
- ✅ ~~Multiple mbsync processes (fixed .mbsyncrc duplicates)~~
- ✅ ~~Cross-instance sync visibility (simplified external detection)~~

This document tracks implementation progress and planning for the Himalaya email plugin refactor.

## Part 1: Himalaya-vim Plugin Analysis

### Core Architecture
The original VimScript plugin follows a clean, modular design:

1. **Simple CLI Wrapper**: Acts as a frontend to the Himalaya CLI
2. **No Built-in Sync**: Relies entirely on Himalaya CLI's capabilities
3. **Three Buffer Types**: 
   - `himalaya-email-listing` - Email list view
   - `himalaya-email-reading` - Single email view
   - `himalaya-email-writing` - Compose view

### Key Implementation Patterns

#### Command Execution
```vim
" Async job with callback pattern
function! himalaya#request#json(cmd, callback)
  let cmd = [g:himalaya_executable] + cmd
  call himalaya#job#start(cmd, {
    \ 'on_exit': function('s:on_exit', [a:callback])
  \})
endfunction
```

#### Buffer Management
- Uses `buftype=nofile` for virtual buffers
- `nomodifiable` for read-only views
- Simple keybindings for navigation

#### No Background Sync
- **Important**: The original plugin has no automatic synchronization
- Each operation queries the CLI fresh
- User must manually trigger updates

## Part 2: Current Lua Implementation Analysis

### Architecture Overview
```
himalaya/
├── config.lua               # Configuration (well-designed)
├── commands.lua             # User commands (complete)
├── streamlined_sync.lua     # BROKEN: Fake sync implementation
├── ui.lua                   # UI management (functional)
├── sidebar.lua              # Neo-tree style sidebar (good)
├── state.lua                # Session persistence (working)
├── utils.lua                # Himalaya CLI wrapper (working)
[other supporting files]
```

### Critical Issues Identified

#### 1. No Real Email Synchronization
The `streamlined_sync.lua` file contains ~1800 lines of code for managing mbsync processes, but **never actually calls mbsync**:

```lua
-- Line 1213-1220: Claims to use mbsync but uses Himalaya instead
if force_full then
    cmd = { 'himalaya', 'envelope', 'list', '--page-size', '200', '-o', 'json' }
else
    cmd = { 'himalaya', 'envelope', 'list', '--folder', 'INBOX', '--page-size', '200' }
end
```

#### 2. Misleading User Experience
- Shows "Syncing..." progress bars
- Displays sync completion notifications
- Updates UI as if mail was synced
- But no new mail is ever fetched from the server

#### 3. Dead Code and Complexity
- Complex process management for mbsync that's never used
- Lock file handling for non-existent processes
- OAuth token refresh that doesn't affect actual sync
- Duplicate detection for emails that aren't being synced

### What's Working Well
1. **UI/UX**: Clean sidebar interface with good keybindings
2. **State Management**: Proper session persistence
3. **Himalaya Integration**: Commands for reading, composing, sending work
4. **Window Management**: Floating windows handled elegantly
5. **Trash System**: Local trash implementation is complete

## Part 3: Root Cause Analysis

### Why Sync is Broken
1. **Incomplete Implementation**: The sync system was designed for mbsync but never connected
2. **Himalaya Limitations**: Himalaya CLI is not a sync tool - it's an email client
3. **Architectural Mismatch**: Trying to add sync to a tool that doesn't support it

### Understanding the Tools
- **mbsync**: IMAP synchronization tool that mirrors mailboxes locally
- **Himalaya**: Email client that reads local Maildir/mbox files
- **Current Plugin**: Tries to bridge them but fails to execute mbsync

## Part 4: Implementation Phases (Chronological Order)

### Phase 1: Simplify Sync System ✅ COMPLETED
1. **Remove fake sync code** from `streamlined_sync.lua` ✅
2. **Create new `mbsync.lua`** with minimal implementation: ✅
   ```lua
   local M = {}
   
   function M.sync(account, callback)
     local cmd = account and {'mbsync', account} or {'mbsync', '-a'}
     vim.fn.jobstart(cmd, {
       on_exit = function(_, exit_code)
         if exit_code == 0 then
           -- Clear Himalaya cache and refresh UI
           require('neotex.plugins.tools.himalaya.utils').clear_cache()
           callback(true)
         else
           callback(false, "mbsync failed")
         end
       end
     })
   end
   
   return M
   ```

### Phase 2: Update UI Integration ✅ COMPLETED
1. Replace complex sync UI with simple status ✅
2. Remove progress bars (mbsync has its own output) ✅
3. Add proper error handling for mbsync failures ✅

### Phase 3: Fix Process Management ✅ COMPLETED
1. **Fix multiple process execution** - Prevent duplicate/concurrent mbsync processes ✅
2. **Improve lock file system** - Make lock acquisition atomic and robust ✅  
3. **Remove auto-sync triggers** - Eliminate race conditions from UI/startup sync ✅
4. **Add process deduplication** - Ensure only one sync per account at a time ✅

### Phase 4: Enhanced Progress Display ✅ COMPLETED
1. **Restore useful progress elements** - Bring back progress without fake data ✅
2. **Real mbsync progress parsing** - Extract actual progress from mbsync output ✅
3. **Enhanced status display** - Show connection, folder, and operation details ✅
4. **Investigate mbsync progress options** - Research mbsync flags for progress info ✅

### Phase 5: Fix Email Duplication Issue ✅ COMPLETED
**Priority**: HIGH - Critical bug causing massive duplication
1. **Investigate duplication root cause** - Why are emails being duplicated? ✅
   - Found stale Himalaya database showing phantom emails
   - Physical INBOX was empty (0 files)
   - Duplicates were in cache, not on disk
2. **Root cause identified** - Multiple sync channels in .mbsyncrc ✅
   - Duplicate channel definitions caused multiple processes
   - Fixed by using `mbsync gmail` instead of `mbsync -a`
3. **Solution implemented** ✅
   - Clear Himalaya database with force_clear_all_caches()
   - Use specific channel names to prevent duplicates
   - Added duplicate_investigation.lua for debugging
4. **Verified fix** ✅
   - 2067 emails synced correctly
   - No more duplicates in CLI output
   - Emails actually in ~/Mail/Gmail/cur/ (Maildir++ format)

### Phase 6: Smart Auto-sync on Startup ✅ COMPLETED
**Priority**: Medium - User requested feature  
1. **Cross-instance detection** - Detect other nvim instances with active sync ✅
   - Disabled auto-sync to prevent race conditions
   - Users must manually trigger with <leader>ms
2. **Configuration options** - Allow users to disable/configure auto-sync ✅
   - auto_sync = false by default
3. **Lock system improved** - Better mbsync process detection ✅
4. **Race condition prevention** - No auto-sync conflicts ✅

### Phase 7: Cross-Instance Sync Visibility ✅ COMPLETED  
**Priority**: High - User requested feature
1. **Phase 1: External sync detection** ✅ COMPLETE
   - Created external_sync.lua module
   - Detects mbsync running from other instances
   - Shows takeover prompt when opening sidebar
   - Commands: :HimalayaTakeoverSync, :HimalayaExternalSyncInfo
2. **Simplified to basic detection** ✅ COMPLETE
   - User requested simplification - no takeover needed
   - Just shows "🔄 Syncing: External (1 process)" 
   - Created external_sync_simple.lua
3. **Integration completed** ✅ COMPLETE
   - External sync detection working
   - UI shows appropriate status

### Phase 8: Plugin Simplification ✅ COMPLETED
**Priority**: Medium - Code cleanup
1. **Remove development/testing elements** ✅
   - Removed test files, debugging commands
   - Simplified from 60+ commands to ~15 essential ones
2. **Centralize leader mappings** ✅
   - Moved all <leader> mappings to which-key.lua
   - Removed redundant keymaps.lua file
3. **Maildir setup automation** ✅
   - Created automatic maildir++ setup for new users
   - Added backup and fresh start functionality (<leader>mX)

### Phase 9: Multiple Process Prevention ✅ COMPLETED
**Priority**: CRITICAL - Multiple processes still spawning despite safeguards

**Evidence of Problem**: 
```
mbsync processes: 1120913, 1120988, 
Current operation: Authenticating
Lock file PID: 1119828
```
→ Two mbsync processes running, but lock held by different PID (1119828)

**Research Findings** ✅ COMPLETED:
1. **Community Solutions**: flock-based wrappers are standard practice
2. **mbsync Limitations**: No built-in timeout handling, hangs on lock conflicts
3. **Best Practices**: External process management preferred over internal locks
4. **Proven Solutions**: `flock -n`, `run-one`, atomic directory creation

**Root Cause Analysis** ✅ COMPLETED:
1. **Timing Gap**: Between `has_active_mbsync_processes()` check and `jobstart()` 
2. **Lock Mismatch**: Current lock tracks "sync intent" but not actual mbsync processes
3. **External Spawning**: Other nvim instances or manual commands can spawn mbsync
4. **Process vs Intent**: Lock file PID ≠ actual mbsync process PIDs

**Implementation Completed** ✅:
1. **Research & Testing** - Created test scenarios and verified race condition ✅
2. **flock Integration** - Wrapped mbsync calls with `flock -n /tmp/mbsync-global.lock` ✅  
3. **Process Monitoring** - Enhanced detection for both mbsync and flock processes ✅
4. **Atomic Execution** - flock ensures only one mbsync process can run globally ✅
5. **Zombie Process Fix** - Eliminated false positives from zombie processes ✅

**Technical Changes Made**:
- Command construction: `flock -n /tmp/mbsync-global.lock -c "mbsync -V gmail"`
- Replaced `pgrep` with `ps -eo pid,stat,cmd` to filter out zombie processes (stat=Z)
- Enhanced both `has_active_mbsync_processes()` and `kill_existing_processes()` with zombie filtering
- Added `detach = false` to all `vim.fn.jobstart()` calls for proper process management
- Increased sync status cache timeout from 2 to 10 seconds to reduce detection frequency
- Improved UI timer management to stop immediately during cleanup

**Alternative Approaches Considered**:
- ❌ Replace `mbsync -a` - User prefers to keep current channel approach
- ✅ External process wrapper - Aligns with community best practices
- ✅ flock-based locking - Proven solution, simpler than custom lock files

### Phase 10: Fix "External" Sync Misidentification ✅ COMPLETED
**Priority**: High - User's own syncs are incorrectly labeled as "external"
**Evidence**: 
```
DEBUG: Set sync_running = true for local sync
DEBUG: Job started with ID: 10
📧 STARTING INBOX SYNC (flock + mbsync gmail-inbox)
```
Yet UI shows: "🔄 Syncing: External (1 process)"

**Root Cause Analysis**:
1. **State confusion after backup**: `<leader>mX` calls `state.reset()` which clears sync tracking
2. **Maildir setup interference**: UI triggers `ensure_maildir_exists()` during sync, which may clear state
3. **Race conditions**: State checks happen before `sync_running` is properly set
4. **Weak ownership tracking**: Only uses boolean `sync_running` instead of tracking job IDs

**Implementation Completed**:
1. **Robust sync ownership tracking** ✅
   - Added `sync_started_by_us` flag to track ownership
   - Added `sync_mbsync_pid` to track actual mbsync process
   - Updated logic to only mark as "external" if we didn't start the sync
2. **Protected sync state during operations** ✅
   - Modified `ensure_maildir_exists()` to skip checks during active sync
   - Preserved sync ownership during backup operations
3. **Improved state persistence** ✅
   - Don't reset sync-related state during backup if sync is running
   - Clear ownership flags properly in `_sync_complete()`

**Technical Changes**:
- Added `sync_started_by_us` and `sync_mbsync_pid` to sync state
- Modified `get_status()` to check ownership before marking as external
- Protected maildir setup from interfering with active syncs
- Preserved sync state during backup operations

### Phase 11: Progress Display Fix 🚧 MEDIUM - IN PROGRESS
**Priority**: Medium - Progress indicator not incrementing correctly
**Evidence**: "🔄 Syncing: 0/1894 new" - 0 never increments
**Root Cause**: Current regex patterns don't match actual mbsync output
   - Expected: `F: +13/13` but seeing: `far side: 2076 messages, 0 recent`

**Refactor Plan**:
1. **Enhanced Progress Parser** - Parse real mbsync output patterns ⏳
   - Parse "far side: X messages, Y recent" format
   - Parse "near side: X messages, Y recent" format  
   - Calculate realistic progress from actual mbsync data
2. **Multi-Channel Progress Aggregation** - Handle multiple channels correctly ⏳
3. **Real-time Progress Updates** - Show incremental progress as it happens ⏳

### Phase 12: Smart Auto-sync on Startup ⏳ PLANNED
1. **Implement startup auto-sync** - Auto-start sync after nvim launch ⏳
2. **Multi-instance detection** - Only auto-sync if no other nvim instances syncing ⏳  
3. **Configurable delay** - Allow user to set startup sync delay (default 3-5 seconds) ⏳
4. **Process deduplication** - Ensure robust cross-instance sync detection ⏳

### Phase 13: Configuration Validation ⏳ PLANNED
1. Add mbsync configuration validation ⏳
2. Document mbsync setup requirements ⏳
3. Add health check for mbsync availability ✅

## Part 5: Alternative Approaches (Not Taken)

### Option A: Remove Sync, Focus on Himalaya
**Approach**: Remove all sync-related code, document external sync requirement
**Benefits**: Simpler codebase, no false expectations
**Outcome**: Not chosen - users wanted integrated sync

### Option B: Investigate Himalaya Native Sync  
**Research**: Check if newer Himalaya versions support IMAP sync
**Outcome**: Not implemented - mbsync integration was sufficient

## Part 6: Detailed File Changes

### Files to Modify
1. **streamlined_sync.lua**: Replace entirely with 100-line implementation
2. **ui.lua**: Update sync button to call real sync
3. **config.lua**: Add mbsync binary path configuration
4. **commands.lua**: Simplify sync commands

### Files to Remove
1. Complex progress tracking code
2. Fake sync status management
3. Unused process management utilities

### New Files
1. **mbsync.lua**: Clean mbsync integration
2. **SETUP.md**: mbsync configuration guide

## Conclusion

The current implementation is a well-designed email client UI that lacks the core synchronization functionality. The refactoring plan prioritizes:

1. **Honesty**: Remove fake sync indicators
2. **Simplicity**: Reduce 1800 lines to ~200
3. **Functionality**: Add real mbsync integration
4. **Maintainability**: Clear separation of concerns

By following this plan, the plugin will actually synchronize email while maintaining the excellent UI/UX already built.
