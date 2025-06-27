# Sync Handoff Implementation Plan

## Overview
This document outlines the implementation of a cross-instance sync management system for the Himalaya email plugin. The goal is to provide detailed sync progress information even when switching between Neovim instances.

## Current Status
Phase 1 is now complete and working! When opening the sidebar in a new instance while sync is running externally:
- ✅ Takeover prompt appears with sync details
- ✅ Shows PID, runtime, command, and stuck warning
- ✅ User can choose to take control or keep external sync
- ✅ External sync progress displayed in sidebar status
- ✅ Progress files written and read across instances

## Problem Statement
- When opening the sidebar in a new Neovim instance while sync is running from another instance
- Only generic status shown: "= Syncing (1 process)"
- No access to detailed progress like "15/98 emails" or operation status
- Users frequently switch between Neovim instances and lose visibility

## Hybrid Implementation Strategy

### Phase 1: Smart Kill & Restart with User Control
**Goal**: Provide immediate solution with minimal disruption

#### 1.1 Detection Logic
```lua
-- In ui.lua when sidebar opens
function M.detect_external_sync()
  local sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  local status = sync.get_status()
  
  if sync.is_sync_running_globally() and not status.sync_running then
    -- External sync detected
    local sync_info = M.analyze_external_sync()
    return true, sync_info
  end
  return false, nil
end

function M.analyze_external_sync()
  -- Parse ps output for sync details
  local handle = io.popen('ps aux | grep mbsync | grep -v grep | head -1')
  local ps_output = handle:read('*a')
  handle:close()
  
  -- Extract command, PID, and runtime
  local pid = ps_output:match('^%S+%s+(%d+)')
  local runtime = ps_output:match('%s+(%d+:%d+)%s+')
  local command = ps_output:match('mbsync%s+(.+)$')
  
  -- Check if sync is likely stuck (> 5 minutes)
  local stuck = false
  if runtime then
    local min = tonumber(runtime:match('(%d+):')) or 0
    stuck = min >= 5
  end
  
  return {
    pid = pid,
    runtime = runtime,
    command = command,
    likely_stuck = stuck
  }
end
```

#### 1.2 User Prompt System
```lua
-- New file: takeover_prompt.lua
function M.show_takeover_prompt(sync_info)
  local lines = {
    'External sync detected:',
    '  Process: ' .. (sync_info.command or 'mbsync'),
    '  Runtime: ' .. (sync_info.runtime or 'unknown'),
    '',
  }
  
  if sync_info.likely_stuck then
    table.insert(lines, '�  This sync appears stuck (> 5 minutes)')
    table.insert(lines, '')
  end
  
  table.insert(lines, 'Take control of this sync?')
  table.insert(lines, '[Y]es - Kill and restart with progress')
  table.insert(lines, '[N]o  - Keep running (basic status only)')
  table.insert(lines, '[A]uto - Always take control (save preference)')
  
  -- Create floating window with prompt
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Handle user response
  -- Y: Kill and restart
  -- N: Show basic status
  -- A: Set auto_takeover = true and proceed
end
```

#### 1.3 Takeover Implementation
```lua
-- In streamlined_sync.lua
function M.takeover_external_sync()
  -- 1. Get sync info
  local sync_info = require('neotex.plugins.tools.himalaya.ui').analyze_external_sync()
  
  -- 2. Kill external process gracefully
  if sync_info.pid then
    os.execute('kill -TERM ' .. sync_info.pid)
    vim.wait(1000)
    -- Force kill if still running
    os.execute('kill -0 ' .. sync_info.pid .. ' 2>/dev/null || kill -KILL ' .. sync_info.pid)
  end
  
  -- 3. Clean up lock file
  M.release_lock()
  
  -- 4. Determine sync type from command
  local force_full = sync_info.command and sync_info.command:match('%-a') or 
                     sync_info.command:match('gmail$')
  
  -- 5. Start new sync with progress
  notify.himalaya('Taking control of sync...', notify.categories.USER_ACTION)
  return M.sync_mail(force_full, true)
end
```

### Phase 2: Progress File Persistence
**Goal**: Share progress between instances without interruption

#### 2.1 Progress File Format
```lua
-- File: /tmp/himalaya-sync-{account}.progress
{
  "pid": 12345,
  "start_time": 1719431234,
  "command": "mbsync gmail-inbox",
  "progress": {
    "current_operation": "Synchronizing emails",
    "messages_processed": 45,
    "messages_total": 98,
    "current_folder": "INBOX",
    "channels_done": 1,
    "channels_total": 1
  },
  "last_update": 1719431290
}
```

#### 2.2 Progress Writer
```lua
-- In streamlined_sync.lua
local function write_progress_file()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.state.current_account or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  
  local progress_data = vim.json.encode({
    pid = M.state.sync_pid,
    start_time = M.state.sync_progress.start_time,
    command = M.state.current_sync_command,
    progress = M.state.sync_progress,
    last_update = os.time()
  })
  
  local file = io.open(progress_file, 'w')
  if file then
    file:write(progress_data)
    file:close()
  end
end

-- Call in parse_sync_progress() to update file
function M._parse_sync_progress(line)
  -- ... existing parsing ...
  
  -- Write progress every few updates
  if M.state.progress_update_count % 5 == 0 then
    write_progress_file()
  end
end
```

#### 2.3 Progress Reader for External Syncs
```lua
-- In ui.lua
function M.read_external_progress()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.state.current_account or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  
  local file = io.open(progress_file, 'r')
  if not file then return nil end
  
  local content = file:read('*a')
  file:close()
  
  local ok, data = pcall(vim.json.decode, content)
  if not ok then return nil end
  
  -- Check if progress is stale (> 30 seconds)
  if os.time() - data.last_update > 30 then
    return nil
  end
  
  return data
end

-- Enhanced status line for external syncs
function M.get_sync_status_line()
  local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  local status = streamlined_sync.get_status()
  
  if not status.sync_running then
    -- Check for external sync
    if streamlined_sync.is_sync_running_globally() then
      local external_progress = M.read_external_progress()
      if external_progress and external_progress.progress then
        -- Show external progress
        local p = external_progress.progress
        local status_text = "= Syncing (external)"
        
        if p.current_message and p.total_messages then
          status_text = status_text .. string.format(": %d/%d emails", 
            p.current_message, p.total_messages)
        elseif p.current_operation then
          status_text = status_text .. ": " .. p.current_operation
        end
        
        return status_text
      end
    end
    return nil
  end
  
  -- ... existing code for local sync ...
end
```

### Phase 3: Graceful Handoff Protocol
**Goal**: Allow seamless sync transfer without interruption

#### 3.1 Enhanced Lock File
```lua
-- Lock file format with handoff request
{
  "pid": 12345,
  "start_time": 1719431234,
  "handoff_requested": true,
  "requestor_pid": 23456
}
```

#### 3.2 Handoff Request
```lua
function M.request_sync_handoff()
  local lock_data = M.read_lock_file()
  if not lock_data then return false end
  
  -- Add handoff request
  lock_data.handoff_requested = true
  lock_data.requestor_pid = vim.fn.getpid()
  
  M.write_lock_file(lock_data)
  
  -- Wait for handoff (max 5 seconds)
  local timeout = 5000
  local start = vim.loop.now()
  
  while vim.loop.now() - start < timeout do
    if not M.has_active_mbsync_processes() then
      -- Handoff complete
      return true
    end
    vim.wait(100)
  end
  
  return false
end
```

#### 3.3 Handoff Check in Running Sync
```lua
-- Add to sync stdout handler
local handoff_check_counter = 0

on_stdout = function(_, data)
  -- ... existing code ...
  
  -- Check for handoff request every 10 lines
  handoff_check_counter = handoff_check_counter + 1
  if handoff_check_counter >= 10 then
    handoff_check_counter = 0
    
    local lock_data = M.read_lock_file()
    if lock_data and lock_data.handoff_requested then
      -- Graceful exit
      notify.himalaya('Handoff requested, saving progress...', notify.categories.STATUS)
      write_progress_file()
      
      -- Terminate mbsync gracefully
      vim.fn.jobstop(job_id)
      M._sync_complete(true, 'Handoff to instance ' .. lock_data.requestor_pid)
      return
    end
  end
end
```

## Configuration Options

```lua
-- In config.lua
M.config = {
  -- ... existing config ...
  
  sync_handoff = {
    enabled = true,
    
    -- Automatically take over external syncs
    auto_takeover = false,
    
    -- Take over if sync running longer than X seconds
    auto_takeover_timeout = 300, -- 5 minutes
    
    -- Show external sync progress from progress files
    show_external_progress = true,
    
    -- Write progress files for sharing
    share_progress = true,
    
    -- How often to write progress (in progress updates)
    progress_write_interval = 5,
    
    -- Enable graceful handoff protocol
    graceful_handoff = false -- Phase 3 feature
  }
}
```

## User Commands

```vim
" Take control of external sync
:HimalayaTakeoverSync

" Request graceful handoff
:HimalayaRequestHandoff

" Show external sync info
:HimalayaExternalSyncInfo

" Toggle auto-takeover
:HimalayaToggleAutoTakeover
```

## Implementation Timeline

### Week 1: Phase 1 Basic Implementation ✅ COMPLETE
- [x] Implement external sync detection
- [x] Create takeover prompt UI
- [x] Add kill & restart logic
- [x] Test with multiple instances

### Week 2: Phase 1 Polish ✅ COMPLETE
- [x] Add configuration options
- [x] Implement auto-takeover logic
- [x] Add user commands
- [x] Fix newline sanitization bug
- [x] Fix incorrect local sync claiming

### Week 3: Phase 2 Progress Sharing 🚧 IN PROGRESS
- [x] Design progress file format
- [x] Implement progress writer (writes every 5 updates)
- [x] Add progress reader
- [x] Update status display (shows external progress)
- [ ] Test progress accuracy across instances
- [ ] Add progress file validation
- [ ] Implement stale progress detection

### Week 4: Testing & Refinement
- [ ] Test edge cases
- [ ] Handle stale progress files
- [ ] Add progress file cleanup
- [ ] Performance optimization

### Future: Phase 3 Graceful Handoff
- [ ] Design handoff protocol
- [ ] Implement lock file extensions
- [ ] Add handoff request/check logic
- [ ] Test seamless transfers

## Testing Plan

### Test Scenarios
1. **Basic Takeover**: Start sync in instance A, open sidebar in instance B
2. **Stuck Sync**: Simulate stuck sync, verify auto-takeover suggestion
3. **Progress Sharing**: Verify progress updates across instances
4. **Rapid Switching**: Switch between instances quickly
5. **Cleanup**: Verify no orphaned processes or files

### Edge Cases
- Sync completes during takeover
- Multiple takeover requests
- Corrupted progress files
- Network interruptions
- System shutdown during sync

## Success Metrics
- Users can see detailed progress in any instance
- No orphaned mbsync processes
- Takeover completes in < 3 seconds
- Progress updates visible within 1 second
- No data corruption or duplicate syncs