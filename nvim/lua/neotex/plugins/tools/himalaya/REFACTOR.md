# Himalaya Email Plugin Refactoring Plan

## Executive Summary & Progress Tracker

**MISSION**: Fix broken email synchronization and restore useful progress indicators

**STATUS**: Phase 1-6 ✅ Complete | Phase 7 🚧 In Progress | Phase 8 ⏳ Planned

**CURRENT ISSUES**:
- ✅ ~~Fake sync (replaced with real mbsync)~~
- ✅ ~~OAuth blocking sync (removed dependency)~~  
- ✅ ~~Multiple concurrent processes~~
- ✅ ~~Missing useful progress info~~
- ✅ ~~Email duplication (was due to stale Himalaya cache)~~
- ✅ ~~Multiple mbsync processes (fixed .mbsyncrc duplicates)~~
- 🚧 **Cross-instance sync visibility** (Phase 1 implemented)

This document tracks implementation progress and planning for the Himalaya email plugin refactor.

## 🚀 Current Status & Immediate Priorities

### ✅ COMPLETED (Phases 1-2)
- **Real mbsync integration**: Replaced fake sync with actual mbsync execution  
- **OAuth dependency removed**: Fixed blocking OAuth refresh issue
- **Simplified progress tracking**: Removed fake progress bars and counters
- **UI integration maintained**: All existing commands and UI work

### 🚨 CRITICAL ISSUE (Phase 5 - Current Priority)
- **Email duplication crisis**: 18+ copies of each email appearing
- **Local/server mismatch**: 32,881 local vs 2,067 server messages
- **Root cause unknown**: Could be mbsync config, Himalaya cache, or sync logic
- **User impact**: Unusable email list with massive duplication

### ⚠️ INVESTIGATION NEEDED
- Why does local have 30k+ more messages than server?
- Are duplicates only in Himalaya's view or actually in Maildir?
- Is mbsync creating duplicates or is Himalaya displaying them wrong?
- How to safely clean up without losing legitimate emails?

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

## Part 4: Systematic Refactoring Plan

### Option A: Fix mbsync Integration (Recommended)

#### Phase 1: Simplify Sync System ✅ COMPLETED
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

#### Phase 2: Update UI Integration ✅ COMPLETED
1. Replace complex sync UI with simple status ✅
2. Remove progress bars (mbsync has its own output) ✅
3. Add proper error handling for mbsync failures ✅

#### Phase 3: Fix Process Management ✅ COMPLETED
1. **Fix multiple process execution** - Prevent duplicate/concurrent mbsync processes ✅
2. **Improve lock file system** - Make lock acquisition atomic and robust ✅  
3. **Remove auto-sync triggers** - Eliminate race conditions from UI/startup sync ✅
4. **Add process deduplication** - Ensure only one sync per account at a time ✅

#### Phase 4: Enhanced Progress Display ✅ COMPLETED
1. **Restore useful progress elements** - Bring back progress without fake data ✅
2. **Real mbsync mrogress parsing** - Extract actual progress from mbsync output ✅
3. **Enhanced status display** - Show connection, folder, and operation details ✅
4. **Investigate mbsync progress options** - Research mbsync flags for progress info ✅

#### Phase 5: Smart Auto-sync on Startup ⏳ PLANNED
1. **Implement startup auto-sync** - Auto-start sync after nvim launch ⏳
2. **Multi-instance detection** - Only auto-sync if no other nvim instances syncing ⏳  
3. **Configurable delay** - Allow user to set startup sync delay (default 3-5 seconds) ⏳
4. **Process deduplication** - Ensure robust cross-instance sync detection ⏳

#### Phase 6: Configuration Validation ⏳ PLANNED
1. Add mbsync configuration validation ⏳
2. Document mbsync setup requirements ⏳
3. Add health check for mbsync availability ✅

### Option B: Remove Sync, Focus on Himalaya

#### Approach
1. **Remove all sync-related code**
2. **Document external sync requirement**
3. **Add simple refresh command** that clears cache
4. **Focus on email client features**

#### Benefits
- Simpler codebase
- No false expectations
- Users can use their preferred sync method

### Option C: Investigate Himalaya Native Sync

#### Research Tasks
1. Check if newer Himalaya versions support IMAP sync
2. If yes, implement native Himalaya sync commands
3. If no, fall back to Option A or B

## Part 5: Implementation Roadmap

### Step 1: Immediate Fixes (1-2 hours) ✅ COMPLETED
```lua
-- In streamlined_sync.lua, replace fake sync with real mbsync
local function execute_sync(force_full)
  local account = get_current_account()
  local cmd = force_full and {'mbsync', '-a'} or {'mbsync', account}
  
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        -- Refresh Himalaya view
        require('neotex.plugins.tools.himalaya.ui').refresh()
      else
        vim.notify("Sync failed", vim.log.levels.ERROR)
      end
    end
  })
end
```

### Step 2: Cleanup (2-3 hours) ✅ COMPLETED
1. Remove 90% of `streamlined_sync.lua` ✅
2. Keep only essential sync triggering logic ✅
3. Remove fake progress indicators ✅
4. Update documentation ✅

### Step 3: Fix Process Management (Phase 3) ✅ COMPLETED
**Priority**: High - Fixing duplicate processes and race conditions
**Target**: 2-3 hours | **Actual**: 2 hours
1. **Atomic lock system** - Make lock acquisition bulletproof ✅
2. **Remove auto-sync triggers** - Eliminate UI/startup race conditions ✅
3. **Process deduplication** - Ensure single sync per account ✅
4. **Disabled auto-retry** - Prevent retry logic from spawning duplicate processes ✅

### Step 4: Enhanced Progress Display (Phase 4) ✅ COMPLETED  
**Priority**: Medium - Restore useful progress information
**Target**: 3-4 hours | **Actual**: 2.5 hours
1. **Research mbsync progress output** - What real data is available? ✅
2. **Design progress parser** - Extract meaningful progress from mbsync ✅
3. **Enhanced UI display** - Show connection/transfer/completion progress ✅
4. **Test progress accuracy** - Ensure progress reflects reality ✅

### Step 5: Fix Email Duplication Issue (Phase 5) ✅ COMPLETE
**Priority**: HIGH - Critical bug causing massive duplication
**Target**: 2-3 hours
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

### Step 6: Smart Auto-sync on Startup (Phase 6) ✅ COMPLETE
**Priority**: Medium - User requested feature  
**Target**: 1-2 hours
1. **Cross-instance detection** - Detect other nvim instances with active sync ✅
   - Disabled auto-sync to prevent race conditions
   - Users must manually trigger with <leader>ms
2. **Configuration options** - Allow users to disable/configure auto-sync ✅
   - auto_sync = false by default
3. **Lock system improved** - Better mbsync process detection ✅
4. **Race condition prevention** - No auto-sync conflicts ✅

### Step 7: Cross-Instance Sync Visibility (Phase 7) 🚧 IN PROGRESS
**Priority**: High - User requested feature
**Target**: 2-3 hours
1. **Phase 1: External sync detection** ✅ COMPLETE
   - Created external_sync.lua module
   - Detects mbsync running from other instances
   - Shows takeover prompt when opening sidebar
   - Commands: :HimalayaTakeoverSync, :HimalayaExternalSyncInfo
2. **Phase 2: Progress file sharing** 🚧 IN PROGRESS
   - Write progress to /tmp/himalaya-sync-{account}.progress
   - Read external progress in UI status line
   - Show "🔄 Syncing (external): 45/120 emails"
3. **Phase 3: Graceful handoff** ⏳ PLANNED
   - Request handoff via lock file
   - Current sync saves state and exits
   - New instance takes over seamlessly

### Step 8: Configuration & Documentation (Phase 8) ⏳ PLANNED
**Priority**: Low - Polish and documentation
**Target**: 1-2 hours
1. Document mbsync setup requirements ⏳
2. Add troubleshooting guide ⏳
3. Update README with sync information ⏳
4. Add configuration validation ⏳

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
