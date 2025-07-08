# Asynchronous Sync Implementation Specification

## Overview

This specification addresses the Neovim UI lag during Himalaya sync operations by implementing a comprehensive asynchronous command architecture. The current implementation uses blocking `vim.fn.system()` calls that freeze the UI during sync operations.

## Problem Analysis

### Current Issues

1. **Blocking Command Execution**: `utils.execute_himalaya()` uses `vim.fn.system()` which blocks the main thread
2. **Auto-Sync Startup Lag**: 2-second startup delay causes immediate sync on Neovim launch
3. **Frequent UI Refreshes**: 5-second refresh timer during sync triggers additional blocking commands
4. **No Cancellation**: Users cannot interrupt long-running sync operations
5. **Cascading Blocking**: UI refreshes trigger `fetch_folder_count()` which blocks further

### Root Cause

The fundamental issue is **synchronous command execution** in a single-threaded environment. Every Himalaya CLI call blocks Neovim's main thread until completion.

## Solution Architecture

### Core Principle: Non-Blocking Operations

Transform all Himalaya operations from blocking to asynchronous using Neovim's job control system (`vim.fn.jobstart`).

### Three-Phase Implementation

## Phase 1: Asynchronous Command Foundation

### 1.1 New Async Command Module

**File**: `lua/neotex/plugins/tools/himalaya/core/async_commands.lua`

```lua
local M = {}

-- Command queue and state management
M.command_queue = {}
M.running_jobs = {}
M.max_concurrent = 3

-- Core async command executor
function M.execute_async(args, opts, callback)
  -- Queue management, timeout handling, error recovery
end

-- Command queuing system
function M.queue_command(args, opts, callback, priority)
  -- Priority: 'user' > 'ui' > 'background'
end

-- Job cancellation
function M.cancel_job(job_id)
  -- Graceful job termination
end

-- Batch operations
function M.execute_batch(commands, callback)
  -- Execute multiple commands efficiently
end
```

### 1.2 Replace Core Execute Function

**File**: `lua/neotex/plugins/tools/himalaya/utils.lua`

```lua
-- Replace execute_himalaya with async version
function M.execute_himalaya_async(args, opts, callback)
  local async_commands = require('neotex.plugins.tools.himalaya.core.async_commands')
  return async_commands.execute_async(args, opts, callback)
end

-- Backward compatibility wrapper
function M.execute_himalaya(args, opts)
  -- For immediate migration, keep sync version but add deprecation warning
  -- Eventually, this should be removed or made async-only
end
```

### 1.3 Async Email Operations

Convert all email operations to callback-based:

```lua
-- Email listing
function M.get_emails_async(account, folder, page, page_size, callback)
  
-- Email reading  
function M.get_email_by_id_async(account, folder, email_id, callback)

-- Folder operations
function M.get_folders_async(account, callback)

-- Count operations
function M.fetch_folder_count_async(account, folder, callback)
```

## Phase 2: Sync Operation Optimization

### 2.1 Enhanced Sync Manager

**File**: `lua/neotex/plugins/tools/himalaya/sync/manager.lua`

```lua
-- Configuration improvements
M.config = {
  startup_delay = 30000,        -- 30 seconds (vs current 2)
  sync_interval = 15 * 60,      -- Keep 15 minutes
  ui_refresh_interval = 10000,  -- 10 seconds during sync (vs current 5)
  max_concurrent_syncs = 1,     -- Prevent overlapping
  timeout = 300000,             -- 5 minute timeout
}

-- Enhanced auto-sync with better timing
function M.start_auto_sync()
  -- Defer startup sync to avoid Neovim launch lag
  -- Use exponential backoff for failed syncs
  -- Add sync health checks
end

-- Sync cancellation
function M.cancel_sync()
  -- Cancel running mbsync jobs
  -- Clean up state
  -- Notify user
end

-- Sync status with more granular control
function M.get_sync_status()
  -- Return detailed status including:
  -- - Current operation
  -- - Progress percentage
  -- - Estimated time remaining
  -- - Cancellation capability
end
```

### 2.2 MBSync Optimization

**File**: `lua/neotex/plugins/tools/himalaya/sync/mbsync.lua`

```lua
-- Optimized job configuration
M.sync_job_config = {
  pty = false,              -- Disable PTY for better performance
  stdout_buffered = true,   -- Buffer for more efficient parsing
  stderr_buffered = true,   -- Better error handling
}

-- Improved progress parsing
function M.parse_progress(data)
  -- Batch process stdout data
  -- Reduce parsing frequency (every 2 seconds vs real-time)
  -- Cache parsed results to avoid redundant work
end

-- Cancellation support
function M.cancel_sync(job_id)
  -- Graceful SIGTERM then SIGKILL
  -- Clean up partial state
  -- Emit cancellation events
end
```

### 2.3 UI Refresh Optimization

**File**: `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

```lua
-- Adaptive refresh rates
M.refresh_config = {
  idle_interval = 60000,      -- 1 minute when idle
  sync_interval = 10000,      -- 10 seconds during sync
  user_action_interval = 2000, -- 2 seconds after user action
}

-- Async email list updates
function M.refresh_email_list_async()
  -- Use async command execution
  -- Cache results to reduce API calls
  -- Update UI incrementally
end

-- Smart cache management
function M.should_refresh_cache(account, folder)
  -- Time-based cache invalidation
  -- Event-based cache invalidation
  -- Size-aware cache limits
end
```

## Phase 3: Background Processing & Advanced Features

### 3.1 Background Job Manager

**File**: `lua/neotex/plugins/tools/himalaya/core/background_jobs.lua`

```lua
local M = {}

-- Job priority system
M.priorities = {
  user = 1,         -- User-initiated actions
  ui = 2,           -- UI updates
  background = 3,   -- Auto-sync, maintenance
}

-- Job scheduling
function M.schedule_job(job_spec, priority)
  -- Intelligent scheduling based on:
  -- - User activity (idle detection)
  -- - System load
  -- - Network conditions
end

-- Resource management
function M.manage_resources()
  -- Limit concurrent operations
  -- Memory usage monitoring
  -- CPU usage consideration
end
```

### 3.2 Intelligent Caching

**File**: `lua/neotex/plugins/tools/himalaya/core/smart_cache.lua`

```lua
local M = {}

-- Multi-level cache
M.cache_levels = {
  memory = {},      -- Fast in-memory cache
  disk = {},        -- Persistent disk cache
  remote = {},      -- Remote state tracking
}

-- Cache strategies
function M.get_with_fallback(key, fetch_func, callback)
  -- 1. Check memory cache
  -- 2. Check disk cache
  -- 3. Fetch from remote (async)
  -- 4. Update all cache levels
end

-- Predictive prefetching
function M.prefetch_likely_data()
  -- Prefetch next page of emails
  -- Prefetch folder counts
  -- Prefetch user's common actions
end
```

### 3.3 User Experience Enhancements

**File**: `lua/neotex/plugins/tools/himalaya/ui/progress.lua`

```lua
local M = {}

-- Enhanced progress display
function M.show_sync_progress(sync_info)
  -- Progress bar with percentage
  -- Estimated time remaining
  -- Current operation description
  -- Cancellation button/keymap
end

-- Non-intrusive notifications
function M.show_background_status(message, type)
  -- Minimal statusline integration
  -- Optional popup for details
  -- Audio/visual indicators for completion
end

-- Performance metrics
function M.show_performance_stats()
  -- Sync duration history
  -- Cache hit rates
  -- Command execution times
  -- Network efficiency metrics
end
```

## Implementation Status

### ✅ Phase 1: Foundation (COMPLETED)
- [x] Create `async_commands.lua` module with job queuing and cancellation
- [x] Implement core async command execution with jobstart
- [x] Add command queuing system with priority levels (user/ui/background)
- [x] Convert core operations to async (emails, folders, counts, delete, move)
- [x] Add timeout handling and retry logic
- [x] Remove backward compatibility code as requested
- [x] Add comprehensive testing with Phase 1 test scripts

### ✅ Phase 2: Sync Optimization (COMPLETED)
- [x] Optimize sync manager configuration (30s startup delay vs 2s)
- [x] Implement sync cancellation for MBSync and async commands
- [x] Add adaptive UI refresh rates (10s during sync, 5s when idle)
- [x] Enhance sync status reporting and state management
- [x] Test Phase 2 implementation with verification scripts

### 🔄 Phase 3: Advanced Features (AVAILABLE FOR FUTURE)
- [ ] Background job management with intelligent scheduling
- [ ] Smart caching with multi-level cache strategy
- [ ] Enhanced progress display with cancellation UI
- [ ] Performance monitoring and metrics

### ✅ Phase 4: Multi-Instance Auto-Sync Coordination (COMPLETED - 2025-01-08)
- [x] Implement coordinator.lua module for primary/secondary election
- [x] Add heartbeat mechanism for liveness detection
- [x] Enforce 5-minute cooldown between syncs across all instances
- [x] Integrate coordinator with sync manager
- [x] Update HimalayaSyncStatus command to show coordination state
- [x] Add coordination configuration to core/config.lua
- [x] Test with multiple Neovim instances

## Configuration

### User Configuration Options

```lua
-- In user's Himalaya config
config.async = {
  enabled = true,
  startup_delay = 30,           -- seconds
  sync_timeout = 300,           -- seconds
  max_concurrent_commands = 3,
  ui_refresh_rate = 10,         -- seconds during sync
  cache_ttl = 300,              -- seconds
  background_priority = true,   -- prefer background jobs when idle
}
```

### Performance Tuning

```lua
config.performance = {
  prefetch_enabled = true,
  cache_size_mb = 50,
  network_timeout = 30,
  retry_attempts = 3,
  exponential_backoff = true,
}
```

## Testing Strategy

### Unit Tests
- Async command execution
- Queue management
- Timeout handling
- Error recovery

### Integration Tests
- Full sync operations
- UI responsiveness during sync
- Multiple concurrent operations
- Cancellation scenarios

### Performance Tests
- Startup time measurement
- Sync duration comparison
- Memory usage monitoring
- UI responsiveness metrics

## Migration Plan

### Phase 1: Gradual Migration
1. Deploy async infrastructure alongside existing sync code
2. Add feature flag for async operations
3. Migrate low-risk operations first (folder listing, email reading)
4. Gather performance data and user feedback

### Phase 2: Core Migration
1. Migrate sync operations to async
2. Add enhanced progress reporting
3. Enable cancellation features
4. Optimize based on real-world usage

### Phase 3: Full Async
1. Remove synchronous fallbacks
2. Enable all advanced features
3. Optimize for edge cases
4. Document performance improvements

## Implementation Results

### Performance Improvements Achieved
- **UI Responsiveness**: Eliminated blocking operations - Himalaya commands no longer freeze Neovim
- **Sync Management**: Added graceful cancellation for all operations
- **Startup Optimization**: Increased auto-sync delay from 2s to 30s to prevent startup lag
- **Adaptive Refresh**: UI refresh rates now adapt to sync status (10s during sync vs 5s idle)

### Key Features Implemented
- **Async Command Infrastructure**: Complete job queuing system with timeout and retry logic
- **Priority-Based Execution**: User actions get highest priority over background operations
- **Comprehensive Cancellation**: All sync operations can be interrupted gracefully
- **Enhanced State Management**: Detailed sync progress and status tracking
- **Clean API**: Removed deprecated functions and backwards compatibility cruft

## Success Metrics

### Performance Improvements
- **Startup Time**: Reduce by 80%+ when sync is needed at startup
- **UI Responsiveness**: Zero blocking operations during sync
- **Sync Speed**: Maintain or improve current sync performance
- **Memory Usage**: No significant increase despite caching

### User Experience
- **Cancellation**: Users can interrupt any long operation
- **Progress Visibility**: Clear feedback on all background operations
- **Perceived Performance**: UI feels responsive at all times
- **Error Recovery**: Graceful handling of network/server issues

## Risk Mitigation

### Complexity Management
- Incremental implementation with feature flags
- Comprehensive testing at each phase
- Clear rollback procedures
- Extensive documentation

### Performance Risks
- Memory usage monitoring and limits
- CPU usage consideration for background jobs
- Network efficiency to avoid overwhelming servers
- Cache size management

### Stability Concerns
- Thorough error handling for all async operations
- Graceful degradation when async fails
- Consistent state management across async boundaries
- Race condition prevention

## Phase 4: Multi-Instance Auto-Sync Coordination ✅ IMPLEMENTED

### Problem Statement

Currently, each Neovim instance starts its own auto-sync timer, leading to:
- Multiple instances attempting to sync at slightly different times
- Excessive sync frequency proportional to the number of open instances
- Lock contention when multiple syncs attempt to run simultaneously
- Unnecessary resource usage and potential rate limiting issues

### 4.1 Instance Coordination Module

**File**: `lua/neotex/plugins/tools/himalaya/sync/coordinator.lua`

```lua
local M = {}
local persistence = require('neotex.plugins.tools.himalaya.core.persistence')
local state = require('neotex.plugins.tools.himalaya.core.state')
local notify = require('neotex.util.notifications')

-- Coordination configuration
M.config = {
  coordination_file = vim.fn.expand('~/.config/himalaya/sync_coordinator.json'),
  heartbeat_interval = 30,      -- 30 seconds
  takeover_threshold = 60,      -- Consider primary dead after 60 seconds
  sync_cooldown = 300,          -- Minimum 5 minutes between syncs
}

-- Instance state
M.instance_id = nil
M.is_primary = false
M.heartbeat_timer = nil

-- Initialize coordination
function M.init()
  M.instance_id = persistence.get_instance_id()
  M.ensure_coordination_file()
  M.check_primary_status()
  M.start_heartbeat()
end

-- Check if this instance should be primary
function M.check_primary_status()
  local coord_data = M.read_coordination_file()
  local now = os.time()
  
  -- Check if current primary is alive
  if coord_data.primary then
    local last_heartbeat = coord_data.primary.last_heartbeat or 0
    local is_stale = (now - last_heartbeat) > M.config.takeover_threshold
    
    if not is_stale and coord_data.primary.instance_id ~= M.instance_id then
      -- Another instance is primary and alive
      M.is_primary = false
      return false
    end
  end
  
  -- Become primary
  M.become_primary()
  return true
end

-- Become the primary sync coordinator
function M.become_primary()
  local coord_data = M.read_coordination_file()
  
  coord_data.primary = {
    instance_id = M.instance_id,
    last_heartbeat = os.time(),
    pid = vim.fn.getpid(),
    nvim_version = vim.version().major .. '.' .. vim.version().minor
  }
  
  M.write_coordination_file(coord_data)
  M.is_primary = true
  
  -- Only show notification in debug mode
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('This instance is now the primary sync coordinator', 
                   notify.categories.BACKGROUND)
  end
end

-- Send heartbeat if primary
function M.send_heartbeat()
  if not M.is_primary then
    -- Check if we should take over
    M.check_primary_status()
    return
  end
  
  local coord_data = M.read_coordination_file()
  
  -- Update our heartbeat
  if coord_data.primary and coord_data.primary.instance_id == M.instance_id then
    coord_data.primary.last_heartbeat = os.time()
    M.write_coordination_file(coord_data)
  else
    -- We lost primary status
    M.is_primary = false
  end
end

-- Check if a sync should be allowed
function M.should_allow_sync()
  local coord_data = M.read_coordination_file()
  local now = os.time()
  
  -- Check last sync time across all instances
  local last_sync = coord_data.last_sync_time or 0
  local time_since_sync = now - last_sync
  
  -- Enforce cooldown period
  if time_since_sync < M.config.sync_cooldown then
    local remaining = M.config.sync_cooldown - time_since_sync
    
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya(string.format('Sync cooldown active: %d seconds remaining', remaining),
                     notify.categories.BACKGROUND)
    end
    
    return false
  end
  
  -- Only primary instance should initiate auto-sync
  return M.is_primary
end

-- Record sync completion
function M.record_sync_completion()
  local coord_data = M.read_coordination_file()
  coord_data.last_sync_time = os.time()
  coord_data.last_sync_instance = M.instance_id
  M.write_coordination_file(coord_data)
end

-- Clean up on exit
function M.cleanup()
  if M.heartbeat_timer then
    M.heartbeat_timer:stop()
    M.heartbeat_timer:close()
  end
  
  -- If we're primary, clear our status
  if M.is_primary then
    local coord_data = M.read_coordination_file()
    if coord_data.primary and coord_data.primary.instance_id == M.instance_id then
      coord_data.primary = nil
      M.write_coordination_file(coord_data)
    end
  end
end

-- Helper functions
function M.ensure_coordination_file()
  local dir = vim.fn.fnamemodify(M.config.coordination_file, ':h')
  vim.fn.mkdir(dir, 'p')
  
  if vim.fn.filereadable(M.config.coordination_file) == 0 then
    M.write_coordination_file({
      version = "1.0",
      created = os.time(),
      primary = nil,
      last_sync_time = 0
    })
  end
end

function M.read_coordination_file()
  local content = vim.fn.readfile(M.config.coordination_file)
  if #content > 0 then
    local ok, data = pcall(vim.fn.json_decode, content[1])
    if ok then return data end
  end
  return { last_sync_time = 0 }
end

function M.write_coordination_file(data)
  data.last_modified = os.time()
  local encoded = vim.fn.json_encode(data)
  vim.fn.writefile({encoded}, M.config.coordination_file)
end

function M.start_heartbeat()
  M.heartbeat_timer = vim.loop.new_timer()
  M.heartbeat_timer:start(0, M.config.heartbeat_interval * 1000, vim.schedule_wrap(function()
    M.send_heartbeat()
  end))
end

return M
```

### 4.2 Modified Auto-Sync Manager

**Updates to**: `lua/neotex/plugins/tools/himalaya/sync/manager.lua`

```lua
-- Add at the top
local coordinator = require('neotex.plugins.tools.himalaya.sync.coordinator')

-- Modified start_auto_sync function
function M.start_auto_sync()
  -- Initialize coordination
  coordinator.init()
  
  -- Record startup time
  startup_time = os.time()
  
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local notify = require('neotex.util.notifications')
  
  -- Check if auto-sync is enabled
  if not config.get('ui.auto_sync_enabled', true) then
    logger.debug('Auto-sync disabled in configuration')
    return
  end
  
  -- Get sync interval and startup delay from config
  local sync_interval = config.get('ui.auto_sync_interval', 15 * 60) -- Default 15 minutes
  local startup_delay = config.get('ui.auto_sync_startup_delay', 30) -- Default 30 seconds
  
  logger.debug('Starting auto-sync with interval: ' .. sync_interval .. 's, startup delay: ' .. startup_delay .. 's')
  
  -- Clear any existing timer
  M.stop_auto_sync()
  
  -- Start timer with initial delay
  auto_sync_timer = vim.loop.new_timer()
  
  -- Start recurring timer after startup delay
  auto_sync_timer:start(startup_delay * 1000, sync_interval * 1000, vim.schedule_wrap(function()
    -- Check coordination before syncing
    if not coordinator.should_allow_sync() then
      logger.debug('Auto-sync skipped by coordinator')
      return
    end
    
    -- Safety check: ensure we've waited the full startup delay
    if startup_time and (os.time() - startup_time) < startup_delay then
      logger.debug('Sync triggered too early, skipping')
      return
    end
    
    -- Only sync if not already syncing
    local current_status = state.get('sync.status', 'idle')
    if current_status ~= 'idle' then
      logger.debug('Skipping auto-sync: sync already in progress')
      return
    end
    
    -- Check if config is initialized
    if not config.is_initialized() then
      logger.debug('Skipping auto-sync: config not initialized')
      return
    end
    
    -- Perform inbox sync
    logger.debug('Starting coordinated auto-sync')
    
    -- Show notification in debug mode only
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya('Auto-syncing inbox (primary coordinator)...', 
                     notify.categories.BACKGROUND)
    end
    
    -- Use the sync_inbox function from main UI module
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    main.sync_inbox()
    
    -- Record sync completion for coordination
    coordinator.record_sync_completion()
  end))
  
  logger.debug('Auto-sync timer started')
  
  -- Show startup notification in debug mode
  if notify.config.modules.himalaya.debug_mode then
    local role = coordinator.is_primary and 'primary coordinator' or 'secondary instance'
    notify.himalaya(string.format('Auto-sync enabled (%s): every %d minutes', 
                                 role, math.floor(sync_interval / 60)), 
                   notify.categories.BACKGROUND)
  end
end

-- Modified stop_auto_sync function
function M.stop_auto_sync()
  if auto_sync_timer then
    auto_sync_timer:stop()
    auto_sync_timer:close()
    auto_sync_timer = nil
    logger.debug('Auto-sync timer stopped')
  end
  
  -- Clean up coordination
  coordinator.cleanup()
end
```

### 4.3 Coordination Status Command

**Add to**: `lua/neotex/plugins/tools/himalaya/core/commands/sync.lua`

```lua
commands.HimalayaSyncStatus = {
  fn = function()
    local coordinator = require('neotex.plugins.tools.himalaya.sync.coordinator')
    local float = require('neotex.plugins.tools.himalaya.ui.float')
    
    local coord_data = coordinator.read_coordination_file()
    local lines = {
      '# Himalaya Sync Coordination Status',
      '',
      '## Current Instance',
      string.format('  Instance ID: %s', coordinator.instance_id),
      string.format('  Role: %s', coordinator.is_primary and 'Primary Coordinator' or 'Secondary'),
      string.format('  PID: %d', vim.fn.getpid()),
      '',
    }
    
    if coord_data.primary then
      table.insert(lines, '## Primary Coordinator')
      table.insert(lines, string.format('  Instance: %s', coord_data.primary.instance_id))
      table.insert(lines, string.format('  PID: %d', coord_data.primary.pid or 0))
      
      local heartbeat_age = os.time() - (coord_data.primary.last_heartbeat or 0)
      table.insert(lines, string.format('  Last Heartbeat: %d seconds ago', heartbeat_age))
      table.insert(lines, string.format('  Status: %s', 
        heartbeat_age < 60 and 'Active' or 'Possibly Stale'))
      table.insert(lines, '')
    else
      table.insert(lines, '## Primary Coordinator')
      table.insert(lines, '  No primary coordinator active')
      table.insert(lines, '')
    end
    
    table.insert(lines, '## Sync History')
    local last_sync = coord_data.last_sync_time or 0
    if last_sync > 0 then
      local sync_age = os.time() - last_sync
      local age_str
      if sync_age < 60 then
        age_str = sync_age .. ' seconds ago'
      elseif sync_age < 3600 then
        age_str = math.floor(sync_age / 60) .. ' minutes ago'
      else
        age_str = math.floor(sync_age / 3600) .. ' hours ago'
      end
      
      table.insert(lines, string.format('  Last Sync: %s', age_str))
      table.insert(lines, string.format('  By Instance: %s', 
        coord_data.last_sync_instance or 'Unknown'))
    else
      table.insert(lines, '  No sync history recorded')
    end
    
    local cooldown_remaining = coordinator.config.sync_cooldown - 
                              (os.time() - last_sync)
    if cooldown_remaining > 0 then
      table.insert(lines, string.format('  Cooldown: %d seconds remaining', cooldown_remaining))
    else
      table.insert(lines, '  Cooldown: Ready to sync')
    end
    
    float.show('Sync Coordination Status', lines)
  end,
  opts = {
    desc = 'Show sync coordination status'
  }
}
```

### 4.4 Configuration Updates

**Add to default config**: `lua/neotex/plugins/tools/himalaya/core/config.lua`

```lua
-- In the sync section
sync = {
  -- ... existing config ...
  
  -- Multi-instance coordination
  coordination = {
    enabled = true,              -- Enable cross-instance coordination
    heartbeat_interval = 30,     -- Seconds between heartbeats
    takeover_threshold = 60,     -- Seconds before considering primary dead
    sync_cooldown = 300,         -- Minimum seconds between syncs (5 minutes)
  },
},
```

### 4.5 Integration with Notification System

The coordination system integrates seamlessly with the unified notification system:

1. **Debug Mode Only**: Coordination messages use `notify.categories.BACKGROUND`
2. **Minimal Noise**: Only shows role changes and sync skips in debug mode
3. **Status Command**: Detailed coordination info available on demand

### Implementation Benefits

1. **Automatic Coordination**: Instances elect a primary coordinator automatically
2. **Failover Support**: If primary exits, another instance takes over
3. **Sync Rate Limiting**: Enforces minimum time between syncs regardless of instance count
4. **Zero Configuration**: Works out of the box with sensible defaults
5. **Debugging Support**: Status command shows coordination state

### Testing the Coordination

1. Open multiple Neovim instances
2. Run `:HimalayaSyncStatus` in each to see which is primary
3. Close the primary instance and watch another take over
4. Verify only one instance performs auto-sync

## Future Enhancements

### Advanced Features
- Offline mode with sync queuing
- Multi-account parallel sync
- Smart sync scheduling based on usage patterns
- Integration with system power management
- **Load-balanced sync distribution** (future: distribute different folders to different instances)

### Performance Optimizations
- WebSocket-based real-time updates
- Delta sync for large mailboxes
- Compression for cached data
- CDN-style email content caching

This specification provides a comprehensive roadmap for eliminating sync lag while maintaining reliability and enhancing the overall user experience, now with intelligent multi-instance coordination.