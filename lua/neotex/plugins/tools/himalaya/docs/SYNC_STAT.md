# Sync Status Display Implementation

Current implementation of sync status parsing and display for the Himalaya email plugin.

## Current Implementation Status

✅ **RESOLVED** - The sync status display issues have been addressed through comprehensive refactoring in sync/mbsync.lua and the unified sync manager.

## Implementation Overview

The sync system now provides clear, consistent progress information through:

### 1. Unified Sync Manager (`sync/manager.lua`)
- **Coordinates all sync operations** with consistent state management
- **Tracks sync lifecycle** from start to completion with timing
- **Provides unified status** across different sync types (inbox, full)
- **Updates UI in real-time** through state notifications

### 2. Enhanced Progress Parsing (`sync/mbsync.lua`)
- **Folder-focused progress** as primary indicator
- **Real-time message counts** for current folder being synced
- **Clean folder name detection** with common folder mapping
- **Operation type detection** (downloading, uploading, updating flags)

### 3. Improved Display Logic (`ui/email_list.lua`)
- **Progressive disclosure** showing relevant information based on sync stage
- **Consistent format** with folder progress and elapsed time
- **Clear operation context** showing what's currently happening

## Current Display Examples

The new implementation provides these user-friendly displays:

```
# Initial sync start
󰜉 Syncing (0s): Initializing...

# Folder-level progress
󰜉 Syncing (1m 5s): 2/5 folders - INBOX

# Message-level progress within folder
󰜉 Syncing (1m 15s): 2/5 folders - INBOX (45/120) - Downloading

# Operation without specific counts
󰜉 Syncing (2m 10s): 3/5 folders - Sent - Updating flags

# Final summary with statistics
󰜉 Syncing (3m 15s): 5/5 folders | +234 ↻45 -2 emails
```

## Technical Implementation Details

### Progress Data Structure
```lua
progress = {
  status = 'syncing',
  current_folder = 'INBOX',
  folders_done = 2,
  folders_total = 5,
  current_operation = 'Downloading',
  messages_processed = 45,
  messages_total = 120,
  total_new = 234,
  total_updated = 45, 
  total_deleted = 2,
  start_time = os.time()
}
```

### Key Parsing Improvements

1. **Folder Detection** - Robust pattern matching for various mbsync output formats:
   ```lua
   local opening_box = line:match('Opening master box (.+)') or
                       line:match('Opening slave box (.+)') or
                       line:match('Mailbox (.+)') or
                       line:match('Processing mailbox (.+)')
   ```

2. **Progress Parsing** - Focus on meaningful metrics:
   ```lua
   -- Folder progress (primary indicator)
   local mailboxes_done, mailboxes_total = line:match('B:%s*(%d+)/(%d+)')
   
   -- Message progress for current folder  
   local n_added_current, n_added_total = line:match('N:%s*%+(%d+)/(%d+)')
   ```

3. **Clean Folder Names** - Map technical names to user-friendly labels:
   ```lua
   if folder_name:match('All_Mail') or folder_name:match('All Mail') then
     folder_name = 'All Mail'
   elseif folder_name:match('Spam') or folder_name:match('Junk') then
     folder_name = 'Spam'
   end
   ```

### Display Logic Improvements

The `ui/email_list.lua` module now implements progressive disclosure:

```lua
function M.get_sync_status_line_detailed()
  local sync_info = sync_manager.get_sync_info()
  
  -- Base message with elapsed time
  local message = sync_info.message
  if sync_info.start_time then
    local elapsed = os.time() - sync_info.start_time
    message = message .. string.format(" (%ds)", elapsed)
  end
  
  -- Add folder progress
  if progress.folders_total > 0 then
    message = message .. string.format(": %d/%d folders", 
      progress.folders_done, progress.folders_total)
  end
  
  -- Add current folder and operation
  if progress.current_folder then
    message = message .. " - " .. progress.current_folder
    
    -- Add message progress if available
    if progress.messages_total > 0 then
      message = message .. string.format(" (%d/%d)", 
        progress.messages_processed, progress.messages_total)
    end
    
    -- Add operation type
    if progress.current_operation then
      message = message .. " - " .. progress.current_operation
    end
  end
  
  return message
end
```

## Benefits of Current Implementation

1. **Clear Context** - Users always know which folder is being processed
2. **Predictable Progress** - Folder-based progress provides consistent advancement
3. **Granular Detail** - Message counts show progress within each folder
4. **No Confusing Jumps** - Progress only increases, never resets unexpectedly
5. **Meaningful Operations** - Clear indication of what mbsync is doing

## State Management Integration

The sync status integrates with the unified state system:

```lua
-- Sync manager updates state
state.set('sync.status', 'running')
state.set('sync.progress', progress)
state.set('sync.start_time', os.time())

-- UI components read state
local sync_info = sync_manager.get_sync_info()
local status_line = email_list.get_sync_status_line()
```

## Error Handling

The system gracefully handles various error conditions:

1. **Parse Failures** - Continues with existing progress data
2. **Malformed Output** - Filters and cleans mbsync output
3. **Process Termination** - Properly cleans up state
4. **Network Issues** - Maintains last known progress

## Debugging Support

Debug information is available when debug mode is enabled:

```lua
if notify.config.modules.himalaya.debug_mode then
  notify.himalaya('Progress line: ' .. line, notify.categories.BACKGROUND)
  notify.himalaya('Parsed folder progress: ' .. folders_done .. '/' .. folders_total, 
    notify.categories.BACKGROUND)
end
```

## Future Enhancements

Potential improvements identified for future implementation:

1. **Bandwidth Monitoring** - Track sync speed and data transfer
2. **Time Estimation** - Predict remaining sync time based on history
3. **Selective Sync** - Allow syncing specific folders only
4. **Conflict Resolution** - Better handling of sync conflicts
5. **Background Sync** - Optional automatic periodic syncing

## Historical Context

This implementation resolves the original issues documented in this file:
- ❌ ~~Confusing number jumps~~ → ✅ Consistent folder-based progress
- ❌ ~~Mixed operation types~~ → ✅ Clear operation context
- ❌ ~~No completion sense~~ → ✅ Folder progress shows advancement
- ❌ ~~Unpredictable resets~~ → ✅ Progress only increases within folders

The current implementation provides the "clear incremental progress" that users requested, with consistent counts and clear operation context.

## Navigation
- [← Himalaya Plugin](../README.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [Test Documentation](TEST_CHECKLIST.md)